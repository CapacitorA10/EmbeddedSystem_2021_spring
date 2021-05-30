#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <fcntl.h>
#include <time.h>
#include <sys/mman.h>


#define LW_BRIDGE_SPAN 0x00005000
#define LW_BRIDGE_BASE 0xFF200000
#define SOBEL_ACCEL_BASE 0

static volatile int* sobel_accelerator;

// calc sobelmask using C
unsigned char out_img_c[256][256]={0};
void func_sobel(unsigned char img[][256]){

    int gx, gy, sum;
    int i,j,k,m,n;
    int tempx, tempy;
    int check=0;
    char kernel_x[3][3] = { {-1, 0, 1},
                            {-2, 0, 2},
                            {-1, 0, 1}};

    char kernel_y[3][3] = { { 1, 2, 1},
                            { 0, 0, 0},
                            {-1,-2,-1}};
    for(i = 1; i < 256; i++){
        for(j = 1; j < 256; j++){
            for(k = 0; k <100; k++){ //k는 단순 반복용(시간 차 확인)
                tempx = 0;
                tempy = 0;
                for(m = 0; m < 3; m++){
                    for(n = 0; n < 3; n++){
                        tempx += img[i-1+m][j-1+n] * kernel_x[m][n];
                        tempy += img[i-1+m][j-1+n] * kernel_y[m][n];
                    }
                }
                gx = tempx;                
                gy = tempy;
                gx = abs(gx);
                gy = abs(gy);
                sum = gx + gy;
                if(sum>255) sum = 255; //limit max val 255
                
                out_img_c[i-1][j-1] = sum;
            }
        }
    }
}

// calc sobelmask using Verilog
unsigned char out_img_v[256][256]={0};
void acc_sobel(unsigned char img[][256]){

    int row0, row1, row2, row3, row4, row5;
    int output1, output2;
    int i,j,k;

    for(i = 1; i < 252; i+=4){
        for(j = 1; j < 254; j+=2){
            //data separate
            row0 = ( (img[i-1][j-1]<<24) | (img[i-1][j]<<16) 
                    | (img[i-1][j+1]<<8) | (img[i-1][j+2]) );
            row1 = ( (img[i][j-1]<<24) | (img[i][j]<<16) 
                    | (img[i][j+1]<<8) | (img[i][j+2]) );
            row2 = ( (img[i+1][j-1]<<24) | (img[i+1][j]<<16) 
                    | (img[i+1][j+1]<<8) | (img[i+1][j+2]) );
            row3 = ( (img[i+2][j-1]<<24) | (img[i+2][j]<<16) 
                    | (img[i+2][j+1]<<8) | (img[i+2][j+2]) );
            row4 = ( (img[i+3][j-1]<<24) | (img[i+3][j]<<16) 
                    | (img[i+3][j+1]<<8) | (img[i+3][j+2]) );
            row5 = ( (img[i+4][j-1]<<24) | (img[i+4][j]<<16) 
                    | (img[i+4][j+1]<<8) | (img[i+4][j+2]) );

            // calc
            for(k = 0; k <100; k++){
                *sobel_accelerator = row0;
                *(sobel_accelerator+1) = row1;
                *(sobel_accelerator+2) = row2;
                *(sobel_accelerator+3) = row3;
                *(sobel_accelerator+4) = row4;
                *(sobel_accelerator+5) = row5;
                output1 = *(sobel_accelerator+6);
                output2 = *(sobel_accelerator+7);
                // image matching
                out_img_v[i-1][j-1] = (unsigned char)(output1 >> 24);
                out_img_v[i-1][j] = (unsigned char)(output1 >> 16);
                out_img_v[i][j-1] = (unsigned char)(output1 >> 8);
                out_img_v[i][j] = (unsigned char)(output1);

                out_img_v[i+1][j-1] = (unsigned char)(output2 >> 24);
                out_img_v[i+1][j] = (unsigned char)(output2 >> 16);
                out_img_v[i+2][j-1] = (unsigned char)(output2 >> 8);
                out_img_v[i+2][j] = (unsigned char)(output2);
            }

        }
    }
}
int main(void){
    int fd;
    void *lw_virtual;

    FILE* fpi, *fpo_c, *fpo_v;
    clock_t c1, c2, v1, v2;
    unsigned char in_img[256][256];
    
    // memory mapped io load
    fd = open("/dev/mem", (O_RDWR | O_SYNC));
    lw_virtual = mmap(NULL, LW_BRIDGE_SPAN, (PROT_READ | PROT_WRITE), MAP_SHARED, fd, LW_BRIDGE_BASE);
    sobel_accelerator = (volatile int *)(lw_virtual+SOBEL_ACCEL_BASE);

    // image file read
    fpi = fopen("lena.raw","rb");
    fpo_c = fopen("lena_edge_c.raw","wb");
    fpo_v = fopen("lena_edge_v.raw","wb");
    if((fpi==NULL) | (fpo_c==NULL) | (fpo_v==NULL)){
        printf("File read failure!\n");
        exit(-1);
    }
    fread(in_img, 256*256, sizeof(unsigned char), fpi);
    
    // calc edge using c
    c1 = clock();
    func_sobel(in_img);
    c2 = clock();
    printf("Using C consume %f \n",(float)(c2 - c1)/CLOCKS_PER_SEC);
    fwrite(out_img_c, 256*256, sizeof(unsigned char), fpo_c);

    // calc edge using verilog
    v1 = clock();
    acc_sobel(in_img);
    v2 = clock();
    printf("Using V consume %f \n",(float)(v2 - v1)/CLOCKS_PER_SEC);
    fwrite(out_img_v, 256*256, sizeof(unsigned char), fpo_v);

    // close files
	fclose(fpi);
	fclose(fpo_c);
    fclose(fpo_v);

    printf("transform done\n");

    return 0;
    
}
