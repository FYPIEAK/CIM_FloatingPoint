`timescale 1ns / 1ps

module tb_ReDCIM;

parameter SIZE = 2;

// Inputs
reg clk;
reg rst_n;
reg [16*SIZE-1:0] BF16_A;
reg [16*SIZE-1:0] BF16_B;
reg start;

// Outputs
wire [15:0] BF16_out;

// 实例化被测试模块
ReDCIM uut (
    .clk(clk), 
    .rst_n(rst_n), 
    .start(start),
    .BF16_A(BF16_A), 
    .BF16_B(BF16_B), 
    .BF16_out(BF16_out)
);

initial begin
    clk = 0;
    rst_n = 0;
    BF16_A = 0;
    BF16_B = 0;
    start = 0;

    #20;
    rst_n = 1;
    start = 1;
    BF16_A = {16'b1_10000101_1000000, 16'b1_10000011_0111011}; 
    BF16_B = {16'b0_10000101_0100011, 16'b0_10000001_0101010};
    //-18.3964*34.1843 + (-38.3963)*71.6737 = -3380.65
    //simulation result:c5f6 = -3840
    #20 
    start = 0;
    #1000;
    $finish;
end

// 时钟信号产生
always #10 clk = ~clk;

endmodule
