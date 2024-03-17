`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/03/12 21:03:16
// Design Name: 
// Module Name: ReDCIM
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
/*


*/

module ReDCIM #(
    parameter SIZE = 2
)
(
    input                   clk       ,
    input                   rst_n     ,
    input                   start     ,
    input [16*SIZE-1:0]     BF16_A    ,
    input [16*SIZE-1:0]     BF16_B    ,
    output reg [15:0]       BF16_out  
    );

//reg define
reg [7:0]       A_exp               [SIZE-1:0];
reg [7:0]       B_exp               [SIZE-1:0];
reg [7:0]       A_exp_diff          [SIZE-1:0];
reg [7:0]       B_exp_diff          [SIZE-1:0];

reg [6:0]       A_mant              [SIZE-1:0];
reg [6:0]       B_mant              [SIZE-1:0];
reg [7:0]       A_mant_extend       [SIZE-1:0];
reg [7:0]       B_mant_extend       [SIZE-1:0];
reg [15:0]       A_mant_shift       [SIZE-1:0];
reg [15:0]       B_mant_shift       [SIZE-1:0];
reg [SIZE-1:0]    A_sign,B_sign               ;
reg [3:0]       state                         ;
reg [7:0]       max_exp                  [1:0];
reg [31:0]      partial_product      [SIZE-1:0]; //原本两个尾数8位，乘积16位，但是因为需要做带符号乘法，需要用2个16位先乘出32位，加和时再取出低16位
reg [16:0]      partial_product_17   [SIZE-1:0];
reg [SIZE-1:0]  partial_product_sign          ;
reg [7:0]       result_exp                    ;
reg [6:0]       result_mantisa                ;
reg             result_sign                   ;
reg             flag                          ;
//wire define


//parameter
parameter IDLE   = 4'd0, //拆分数据
          ALIGN  = 4'd1, //对齐指数,找最大的指数
          DIFF   = 4'd2,
          SHIFT  = 4'd3, //根据指数，将尾数对应进行移位
          MUL    = 4'd4, //尾数相乘
          ADD    = 4'd5, //尾数部分和相加，指数相加
          EXTRACT= 4'd6, //提取符号位并取回原码
          ONE    = 4'd7, //找leading one的位置
          NORMAL = 4'd8,
          OUT    = 4'd9,
          DONE   = 4'd10;
integer i,j,k;

// function called clogb2 that returns an integer which has the value of the ceiling of the log base 2.
function integer clogb2 (input integer size);
begin
  for(clogb2=0; size>0; clogb2=clogb2+1)
    size = size >> 1;
end
endfunction
localparam MAX_SUM = (2**16) * SIZE         ; 
localparam BIT_NUM = clogb2(MAX_SUM-1)      ;
localparam bit_num = clogb2(BIT_NUM-1);
reg [BIT_NUM-1:0]     sum                   ;
reg [bit_num:0]       leading_one_position  ;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        leading_one_position <= 0;
        A_sign               <= 0;
        B_sign               <= 0;
        result_exp           <= 0;
        result_mantisa       <= 0;
        result_sign          <= 0;
        flag                 <= 0;
        state                <= IDLE;
        sum                  <= 0;

    end
    else begin
        case (state)
            IDLE: begin
                for (i = 0; i < SIZE; i = i + 1) begin
                    A_sign[i] <= BF16_A[(16*SIZE-1) - i*16]; 
                    A_exp[i]  <= BF16_A[(16*SIZE-2) - i*16 -: 8]; 
                    A_mant[i] <= BF16_A[(16*SIZE-10) - i*16 -: 7]; 
        
                    B_sign[i] <= BF16_B[(16*SIZE-1) - i*16]; 
                    B_exp[i]  <= BF16_B[(16*SIZE-2) - i*16 -: 8];
                    B_mant[i] <= BF16_B[(16*SIZE-10) - i*16 -: 7];
                end
                max_exp[0] <= A_exp[0];
                max_exp[1] <= B_exp[0];
                state <= ALIGN;
            end
            ALIGN:begin
                for (i = 0; i < SIZE; i = i + 1) begin
                    if (A_sign[i]) begin
                        A_mant_extend[i] <= {1'b0,{~A_mant[i] + 1'b1}};
                    end
                    else begin
                        A_mant_extend[i] <= {1'b1,A_mant[i]};
                    end
                    if (B_sign[i]) begin
                        B_mant_extend[i] <= {1'b0,{~B_mant[i] + 1'b1}};
                    end
                    else begin
                        B_mant_extend[i] <= {1'b1,B_mant[i]};
                    end
                end
                for (j = 1; j < SIZE; j = j + 1) begin
                    if (A_exp[j] > max_exp[0])
                        max_exp[0] <= A_exp[j];
                    if (B_exp[j] > max_exp[1])
                        max_exp[1] <= B_exp[j];
                end
                state <= DIFF;
                sum   <= 0;
            end
            DIFF: begin
                for (i = 0; i < SIZE; i = i + 1 ) begin
                    A_exp_diff[i] <= max_exp[0] - A_exp[i];
                    B_exp_diff[i] <= max_exp[1] - B_exp[i];
                end
                state <= SHIFT;
            end
            SHIFT:begin
                for (i = 0; i < SIZE; i = i + 1) begin
                    //redcim 中 计算尾数的构成是1位符号位+补充位+6位尾数位
                    //B_mant_shift[i] <= {{B_exp_diff[i]{B_sign[i]}}, B_mant_extend[i][7 -:B_exp_diff[i]]}  ; 
                    if (A_exp_diff[i] == 8'd1) begin
                        A_mant_shift[i] <= {{10{A_sign[i]}}, A_mant_extend[i][7:2]}; 
                    end else if (A_exp_diff[i] == 8'd2) begin
                        A_mant_shift[i] <= {{11{A_sign[i]}}, A_mant_extend[i][7:3]};  
                    end else if (A_exp_diff[i] == 8'd3) begin
                        A_mant_shift[i] <= {{12{A_sign[i]}}, A_mant_extend[i][7:4]};  
                    end else if (A_exp_diff[i] == 8'd4) begin
                        A_mant_shift[i] <= {{13{A_sign[i]}}, A_mant_extend[i][7:5]};  
                    end else if (A_exp_diff[i] == 8'd5) begin
                        A_mant_shift[i] <= {{14{A_sign[i]}}, A_mant_extend[i][7:6]};  
                    end else if (A_exp_diff[i] == 8'd6) begin
                        A_mant_shift[i] <= {{15{A_sign[i]}}, A_mant_extend[i][7]};  
                    end else if (A_exp_diff[i] == 8'd7) begin
                        A_mant_shift[i] <= {{16{A_sign[i]}}};  
                    end else begin
                        A_mant_shift[i] <= {{9{A_sign[i]}}, A_mant_extend[i][7:1]};
                    end

                    if (B_exp_diff[i] == 8'd1) begin
                        B_mant_shift[i] <= {{10{B_sign[i]}}, B_mant_extend[i][7:1]}; 
                    end else if (B_exp_diff[i] == 8'd2) begin
                        B_mant_shift[i] <= {{11{B_sign[i]}}, B_mant_extend[i][7:2]};  
                    end else if (B_exp_diff[i] == 8'd3) begin
                        B_mant_shift[i] <= {{12{B_sign[i]}}, B_mant_extend[i][7:3]};  
                    end else if (B_exp_diff[i] == 8'd4) begin
                        B_mant_shift[i] <= {{13{B_sign[i]}}, B_mant_extend[i][7:4]};  
                    end else if (B_exp_diff[i] == 8'd5) begin
                        B_mant_shift[i] <= {{14{B_sign[i]}}, B_mant_extend[i][7:5]};  
                    end else if (B_exp_diff[i] == 8'd6) begin
                        B_mant_shift[i] <= {{15{B_sign[i]}}, B_mant_extend[i][7:6]};  
                    end else if (B_exp_diff[i] == 8'd7) begin
                        B_mant_shift[i] <= {{16{B_sign[i]}}};  
                    end else begin
                        B_mant_shift[i] <= {{9{B_sign[i]}}, B_mant_extend[i][7:1]}; 
                    end
                end
                state <= MUL;
            end
            MUL:begin
                for (i = 0; i < SIZE; i = i + 1) begin
                    partial_product[i] <= A_mant_shift[i] * B_mant_shift[i]; 
                end
                for (i = 0; i < SIZE; i = i + 1) begin
                    partial_product_17[i] <= partial_product[i][16:0];
                end
                
                state <= ADD;
            end
            ADD:begin
                for (j = 0; j < SIZE; j = j + 1) begin
                    sum = sum + partial_product_17[j]; //????????????
                end
                result_exp <= max_exp[0] + max_exp[1] - 8'd127;
                state <= EXTRACT;
            end
            EXTRACT:begin
                if (sum[BIT_NUM-1] == 1'b1) begin
                    result_sign <= 1'b1;
                    sum[BIT_NUM-2:0] <= ~sum[BIT_NUM-2:0] + 1'b1; //转回原码时符号位不变
                end
                else begin
                    result_sign <= 1'b0;
                end
                state <= ONE;
                flag <= 0;
            end
            ONE:begin
                for (i = BIT_NUM - 2; i >= 0; i = i - 1) begin //忽视符号位向下找
                    if (sum[i] == 1'b1 && (flag == 0)) begin
                        leading_one_position = i;  //????????????????????????
                        flag = 1; 
                    end
                end
                state <= NORMAL;
            end
            NORMAL:begin
                if (leading_one_position >= 7) begin
                    result_mantisa <= sum[(leading_one_position-1) -:7]; //不包括leading_one_position 位
                end
                else if (leading_one_position == 6) begin
                    result_mantisa <= {sum[5:0],1'b0}; 
                end
                else if (leading_one_position == 5) begin
                    result_mantisa <= {sum[4:0],{2{1'b0}}}; 
                end
                else if (leading_one_position == 4) begin
                    result_mantisa <= {sum[3:0],{3{1'b0}}}; 
                end
                else if (leading_one_position == 3) begin
                    result_mantisa <= {sum[2:0],{4{1'b0}}}; 
                end
                else if (leading_one_position == 2) begin
                    result_mantisa <= {sum[1:0],{5{1'b0}}}; 
                end
                else if (leading_one_position == 1) begin
                    result_mantisa <= {sum[0],{6{1'b0}}}; 
                end
                else if (leading_one_position == 0) begin
                    result_mantisa <= 0; 
                end
                result_exp <= result_exp - (12-leading_one_position);//两个数相乘，小数点应该在低12位前
                state <= OUT;
            end
            OUT:begin
                BF16_out <= {result_sign,result_exp,result_mantisa};
                state <= DONE;
            end
            DONE:begin
                leading_one_position <= 0;
                A_sign               <= 0;
                B_sign               <= 0;
                result_exp           <= 0;
                result_mantisa       <= 0;
                result_sign          <= 0;
                flag                 <= 0;
                state                <= IDLE;
                sum                  <= 0;
                BF16_out <= {result_sign,result_exp,result_mantisa};
                if (start) begin
                    state <= IDLE ;
                end
            end
            default: begin
                state <= IDLE;
            end
        endcase
    end
end
endmodule
