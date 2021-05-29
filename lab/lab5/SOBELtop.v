module TOP(
        //Avalon MM I/F
        input   wire    [ 2:0]   addr,
        output  reg     [31:0]   rdata,     //output image는 2*2가 출력되므로 32bit
        input   wire    [31:0]   wdata,     //input image = 4*4-> 1행에 4pixel = 32bit, addr로 0,1,2,3행 접근
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

    assign p20 = data2[31:24];
    assign p21 = data2[23:16];
    assign p22 = data2[15: 8];
    assign p23 = data2[ 7: 0];

    assign p30 = data3[31:24];
    assign p31 = data3[23:16];
    assign p32 = data3[15: 8];
    assign p33 = data3[ 7: 0];

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
            data0 <= wdata;
        end 
    // input register B
    always @ (posedge clk)
        if(cs & write & (addr == 3'b001)) begin
            data1 <= wdata;
        end 
    // input register C
    always @ (posedge clk)
        if(cs & write & (addr == 3'b010)) begin
            data2 <= wdata;
        end 
    // input register D
    always @ (posedge clk)
        if(cs & write & (addr == 3'b011)) begin
            data3 <= wdata;
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
                default: rdata <= 32'd0;
            endcase

endmodule
