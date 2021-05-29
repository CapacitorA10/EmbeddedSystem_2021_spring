module TOP(
        //Avalon MM I/F
        input   wire    [ 2:0]   addr,
        output  reg     [32:0]   rdata,     //output image는 2*2가 출력되므로 32bit
        input   wire    [32:0]   wdata,     //input image = 4*4-> 1행에 4pixel = 32bit, addr로 0,1,2,3행 접근
        input   wire    [ 3:0]   byteenable,
        input   wire             cs,
        input   wire             read,
        input   wire             write,

        //Avlaon clock & reset I/F
        input   wire            clk,
        input   wire            rst
);
    //input data writedata matrix를 pixelwise하게
    wire [7:0] p00, p01, p02, p03; 
    wire [7:0] p10, p11, p12, p13;
    wire [7:0] p20, p21, p22, p23;
    wire [7:0] p30, p31, p32, p33;

    // input data save register
    reg [31:0] data0, data1, data2, data3;
    // output data wire?reg?
    wire [7:0] out_p0, out_p1, out_p2, out_p3; //rdata[31:0] = {outp0...outp3}

    // input data separate
    assign p00 = data0[31:24];
    assign p01 = data0[23:16];
    assign p02 = data0[15: 8];
    assign p03 = data0[ 7: 0];

    assign p10 = data1[31:24];
    assign p11 = data1[23:16];
    assign p12 = data1[15: 8];
    assign p13 = data1[ 7: 0];

    assign p20 = data2[63:56];
    assign p21 = data2[55:48];
    assign p22 = data2[47:40];
    assign p23 = data2[39:32];

    assign p30 = data3[31:24];
    assign p31 = data3[23:16];
    assign p32 = data3[15:8];
    assign p33 = data3[7:0];

    // using module for sobel mask
    SOBEL U0 (.p0(p00), .p1(p01), .p2(p02), .p3(p10), .p5(p12), .p6(p20), .p7(p21), .p8(p22),
                .out(out_p0));
    SOBEL U1 (.p0(p01), .p1(p02), .p2(p03), .p3(p11), .p5(p13), .p6(p21), .p7(p22), .p8(p23),
                .out(out_p1));
    SOBEL U2 (.p0(p10), .p1(p11), .p2(p12), .p3(p20), .p5(p22), .p6(p30), .p7(p31), .p8(p32),
                .out(out_p2));
    SOBEL U3 (.p0(p11), .p1(p12), .p2(p13), .p3(p21), .p5(p23), .p6(p31), .p7(p32), .p8(p33),
                .out(out_p3));

    // input register A
    always @ (posedge clk)
        if(cs & write & (addr == 3'b000)) begin
            if(byteenable[3]) data0[31:24] <= wdata[31:24];
            if(byteenable[2]) data0[23:16] <= wdata[23:16];
            if(byteenable[1]) data0[15: 8] <= wdata[15: 8];
            if(byteenable[0]) data0[ 7: 0] <= wdata[ 7: 0];
        end 
    // input register B
    always @ (posedge clk)
        if(cs & write & (addr == 3'b001)) begin
            if(byteenable[3]) data1[31:24] <= wdata[31:24];
            if(byteenable[2]) data1[23:16] <= wdata[23:16];
            if(byteenable[1]) data1[15: 8] <= wdata[15: 8];
            if(byteenable[0]) data1[ 7: 0] <= wdata[ 7: 0];
        end 
    // input register C
    always @ (posedge clk)
        if(cs & write & (addr == 3'b010)) begin
            if(byteenable[3]) data2[31:24] <= wdata[31:24];
            if(byteenable[2]) data2[23:16] <= wdata[23:16];
            if(byteenable[1]) data2[15: 8] <= wdata[15: 8];
            if(byteenable[0]) data2[ 7: 0] <= wdata[ 7: 0];
        end 
    // input register D
    always @ (posedge clk)
        if(cs & write & (addr == 3'b011)) begin
            if(byteenable[3]) data3[31:24] <= wdata[31:24];
            if(byteenable[2]) data3[23:16] <= wdata[23:16];
            if(byteenable[1]) data3[15: 8] <= wdata[15: 8];
            if(byteenable[0]) data3[ 7: 0] <= wdata[ 7: 0];
        end 
    // output register
    always @ (posedge clk)
        if(cs & read)
            case(addr)
                3'b000: rdata <= data0; //input
                3'b001: rdata <= data1; //input
                3'b010: rdata <= data2; //input
                3'b011: rdata <= data3; //input
                3'b100: rdata <= {out_p0, out_p1, out_p2, out_p3}; //output
                default: rdata <= 32'dx;
            endcase

endmodule


module SOBEL(
    input wire [7:0] p0, p1, p2, p3, p5, p6, p7, p8, // 글 읽는 방향으로 p0 to p8, and p4 is not needed
    output wire [7:0] out                            //out=p4가 될 것
    );

    wire signed [10:0] gx, gy;           //11 bits because max value of gx and gy is 255*4 and last bit for sign				
    wire signed [10:0] abs_gx, abs_gy;	//it is used to find the absolute value of gx and gy 
    wire [10:0] sum;			        //the max value is 255*8. here no sign bit needed. 

    assign gx = ((p2-p0)+((p5-p3)<<1)+(p8-p6)); //sobel mask for gradient in horiz. direction 
    assign gy = ((p0-p6)+((p1-p7)<<1)+(p2-p8)); //sobel mask for gradient in vertical direction 

    assign abs_gx = (gx[10]? ~gx+1 : gx);	// to find the absolute value of gx. 
    assign abs_gy = (gy[10]? ~gy+1 : gy);	// to find the absolute value of gy. 

    assign sum = (abs_gx+abs_gy);				// finding the sum 
    assign out = (|sum[10:8])?8'hff : sum[7:0];	// to limit the max value to 255  

endmodule
