`timescale 1ns / 1ps

module tb_ReDCIM_new;

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
ReDCIM_new #(
    .SIZE(SIZE)
) uut ( 
    .clk(clk),
    .rst_n(rst_n), 
    .start(start),
    .BF16_A(BF16_A), 
    .BF16_B(BF16_B), 
    .BF16_out(BF16_out)
);

initial begin
    rst_n = 0;
    BF16_A = 0;
    BF16_B = 0;
    start = 0;

    #20;
    rst_n = 1;
    BF16_A = {16'h41BF, 16'h4135}; 
    BF16_B = {16'h4252, 16'hC2BB}; 
    #1000;
    start = 1;
    BF16_A = {16'b1_10000101_1000000, 16'b1_10000011_0111011}; 
    BF16_B = {16'b0_10000101_0100011, 16'b0_10000001_0101010};
    #1000;
    $finish;
end

always #10 clk = ~clk;

endmodule
