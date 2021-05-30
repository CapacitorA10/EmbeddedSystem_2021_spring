module TOP(
        //Avalon MM I/F
        input   wire    [ 2:0]   addr,      //addr 0:5 = 입력, addr 6,7=출력
        output  reg     [31:0]   rdata,     //output image는 2*2가 출력되므로 32bit
        input   wire    [31:0]   wdata,     //input image = 6*4-> 1행에 4pixel = 32bit, addr로 0,1,2,3행 접근
        input   wire             cs,
        input   wire             read,
        input   wire             write,

        //Avlaon clock & reset I/F
        input   wire            clk,
        input   wire            rst
);
    //input data writedata matrix를 pixelwise하게
    // 6 * 4
    wire [7:0] p00, p01, p02, p03; 
    wire [7:0] p10, p11, p12, p13;
    wire [7:0] p20, p21, p22, p23;
    wire [7:0] p30, p31, p32, p33;
    wire [7:0] p40, p41, p42, p43;
    wire [7:0] p50, p51, p52, p53;

    // input data save register
    reg [31:0] data0, data1, data2, data3, data4, data5;
    // output data wire?reg?
    wire [7:0] out_p0, out_p1, out_p2, out_p3, out_p4, out_p5, out_p6, out_p7; //rdata[31:0] = {outp0...outp7}

    // input register
    always @ (posedge clk)
        if(cs & write) 
            case(addr)
                3'b000: data0 <= wdata; //0
                3'b001: data1 <= wdata; //1
                3'b010: data2 <= wdata; //2
                3'b011: data3 <= wdata; //3
                3'b100: data4 <= wdata; //4
                3'b101: data5 <= wdata; //5
            endcase
    
    
    // input data separate
    assign p00 = data0[31:24];
    assign p01 = data0[23:16];
    assign p02 = data0[15: 8];
    assign p03 = data0[ 7: 0];

    assign p10 = data1[31:24];
    assign p11 = data1[23:16];
    assign p12 = data1[15: 8];
    assign p13 = data1[ 7: 0];

    assign p20 = data2[31:24];
    assign p21 = data2[23:16];
    assign p22 = data2[15: 8];
    assign p23 = data2[ 7: 0];

    assign p30 = data3[31:24];
    assign p31 = data3[23:16];
    assign p32 = data3[15: 8];
    assign p33 = data3[ 7: 0];
    
    assign p40 = data4[31:24];
    assign p41 = data4[23:16];
    assign p42 = data4[15: 8];
    assign p43 = data4[ 7: 0];

    assign p50 = data5[31:24];
    assign p51 = data5[23:16];
    assign p52 = data5[15: 8];
    assign p53 = data5[ 7: 0];

    // using module for sobel mask
    SOBEL U0 (.p0(p00), .p1(p01), .p2(p02), .p3(p10), .p5(p12), .p6(p20), .p7(p21), .p8(p22),
                .out(out_p0));
    SOBEL U1 (.p0(p01), .p1(p02), .p2(p03), .p3(p11), .p5(p13), .p6(p21), .p7(p22), .p8(p23),
                .out(out_p1));
    SOBEL U2 (.p0(p10), .p1(p11), .p2(p12), .p3(p20), .p5(p22), .p6(p30), .p7(p31), .p8(p32),
                .out(out_p2));
    SOBEL U3 (.p0(p11), .p1(p12), .p2(p13), .p3(p21), .p5(p23), .p6(p31), .p7(p32), .p8(p33),
                .out(out_p3));

    SOBEL U4 (.p0(p20), .p1(p21), .p2(p22), .p3(p30), .p5(p32), .p6(p40), .p7(p41), .p8(p42),
                .out(out_p4));
    SOBEL U5 (.p0(p21), .p1(p22), .p2(p23), .p3(p31), .p5(p33), .p6(p41), .p7(p42), .p8(p43),
                .out(out_p5));
    SOBEL U6 (.p0(p30), .p1(p31), .p2(p32), .p3(p40), .p5(p42), .p6(p50), .p7(p51), .p8(p52),
                .out(out_p6));
    SOBEL U7 (.p0(p31), .p1(p32), .p2(p33), .p3(p41), .p5(p43), .p6(p51), .p7(p52), .p8(p53),
                .out(out_p7));

    
    // output register
    always @ (posedge clk)
        if(cs & read)
            case(addr)
                3'b000: rdata <= data0; //input
                3'b001: rdata <= data1; //input
                3'b010: rdata <= data2; //input
                3'b011: rdata <= data3; //input
                3'b100: rdata <= data4; //input
                3'b101: rdata <= data5; //input
                3'b110: rdata <= {out_p0, out_p1, out_p2, out_p3}; //output top 2rows
                3'b111: rdata <= {out_p4, out_p5, out_p6, out_p7}; //output bottom 2 rows
            endcase

endmodule
