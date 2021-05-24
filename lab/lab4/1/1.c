#include <stdio.h>
#include <stdlib.h>
FILE *fp_hex, *fp_key;

void key_wait(){
    // key값 무한 대기 & button이 눌리면 break
    int button;
    fp_key = fopen("/dev/key", "r"); //usleep(500000);
    while(!fgetc(fp_key));
    fclose(fp_key);
}

int input_arg(){
    int arg=0;
    
    //키 누르는 내내 arg 1씩 추가 & display
    while(1){
        fp_key = fopen("/dev/key", "r");
        if(!fgetc(fp_key)){ //key가 입력x면 break, 입력중이면 아래 실행
            fclose(fp_key);
            break;
        }
        arg = (arg+1) % 10;
        fputc(arg, fp_hex);
        fflush(fp_hex);
        usleep(500000);
    }
    
    return arg;
}

int input_op(){
    int op=0;
    //키 누르는 내내 op 1씩 추가 & display
    // 0124 = +-*/
    while(1){
        fp_key = fopen("/dev/key", "r");
        if(!fgetc(fp_key)){ //key가 입력x면 break, 입력중이면 아래 실행
            fclose(fp_key);
            break;
        }
        op = (op+1) % 4;
        fputc(op, fp_hex);
        fflush(fp_hex);
        usleep(500000);
    }
    
    return op;
}

int calc(int arg1, int arg2, int op){

    if(op == 0) return (arg1 + arg2);
    else if(op == 1) return (arg1 - arg2);
    else if(op == 2) return (arg1 * arg2);
    else{
        if(arg2 != 0)
            return (arg1 / arg2);
        else
            return 0; //0으로 나눗셈 금지
    }

}


int main(int argc, char *argv[]){
    int arg1, arg2, op, result;
    fp_hex = fopen("/dev/HEX30", "w");

    while(1){
        fputc(0, fp_hex); fflush(fp_hex);
        printf("\ncalculator start...\n\n");    
        
        printf("arg 1 input mode\n");
        key_wait(); // 첫 눌림 시작 전까지 시작 x       
        arg1 = input_arg();
        
        printf("op input mode\n");
        key_wait();
        op = input_op();
        
        printf("arg 2 input mode\n");
        key_wait();
        arg2 = input_arg();
        
        result = calc(arg1, arg2, op);
        fputc(result, fp_hex); fflush(fp_hex);
        printf("result: %d op(%d) %d = %d", arg1, op, arg2, result);
        usleep(5000000); //5초간 결과 출력        
    }
    fclose(fp_hex);

    return 0;
}
