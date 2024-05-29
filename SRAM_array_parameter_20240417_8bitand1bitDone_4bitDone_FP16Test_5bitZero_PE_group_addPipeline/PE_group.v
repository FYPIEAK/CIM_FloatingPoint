module PE_group #(
    parameter COLUMN_NUM = 128,
    parameter ADDER_TREE_OUT_BITWIDTH = 8,
    parameter PE_NUM = 8
) (
    input                                                   clk                   ,
    input                                                   rst_n                 ,
    input                                                   row_sel               ,
    input        [PE_NUM*2-1:0]                             WL                    ,
    input        [COLUMN_NUM*8-1:0]                         BL                    ,
    input        [COLUMN_NUM*8-1:0]                         activations           , // last 2bits: NEG, ZERO
    input        [2:0]                                      mode                  ,
    output   reg [PE_NUM*ADDER_TREE_OUT_BITWIDTH*10 - 1:0]  sum                   ,
    output   reg [PE_NUM*ADDER_TREE_OUT_BITWIDTH*2 -1:0]    compensation_sum
);


reg row_sel_inputReg;
reg [PE_NUM*2-1:0] WL_inputReg;
reg [COLUMN_NUM*8-1:0] BL_inputReg;
reg [COLUMN_NUM*8-1:0] activations_inpurReg;
reg [2:0] mode_inputReg;     
 always @(posedge clk or negedge rst_n) begin
    if(!rst_n) begin
        row_sel_inputReg <= 1'b0;
        WL_inputReg <= {(PE_NUM*2){1'b0}};
        BL_inputReg <= {(COLUMN_NUM*8){1'b0}};
        activations_inpurReg <= {(COLUMN_NUM*8){1'b0}};
        mode_inputReg <= 3'b0;
    end
    else begin
        row_sel_inputReg <= row_sel;
        WL_inputReg <= WL;
        BL_inputReg <= BL;
        activations_inpurReg <= activations;
        mode_inputReg <= mode; 
    end
 end  

// *********************** R_ctrl generate **************************
wire [COLUMN_NUM*8-1:0] R_ctrl;
wire [COLUMN_NUM*8-1:0] R_ctrl_b;

wire [COLUMN_NUM-1:0] ZERO;
wire [COLUMN_NUM-1:0] NEG;
genvar j;
generate 
    for (j=0 ; j<COLUMN_NUM ; j=j+1) begin: activations_change_j
        assign ZERO[j] = activations_inpurReg[j*8]; 
        assign NEG[j]  = activations_inpurReg[j*8+1]; 
    end 
endgenerate

generate 
    for(j=0; j<COLUMN_NUM; j=j+1) begin: R_ctrl_generate
        R_ctrl_generate u_R_ctrl_generate(
            .ZERO               ( ZERO[j]                             ),
            .NEG                ( NEG[j]                              ),
            .activations        ( activations_inpurReg[(j+1)*8-1:j*8] ),
            .mode               ( mode_inputReg                       ),
            .R_ctrl             ( R_ctrl[(j+1)*8-1:j*8]               ),
            .R_ctrl_b           ( R_ctrl_b[(j+1)*8-1:j*8]             )
        );
    end
endgenerate
// *********************** R_ctrl generate **************************

genvar i;
generate 
    for (i=0 ; i<PE_NUM; i=i+1) begin: PE_gen
        PE #(
            .COLUMN_NUM(COLUMN_NUM),
            .ADDER_TREE_OUT_BITWIDTH(ADDER_TREE_OUT_BITWIDTH)
        ) u_PE(
            .clk               ( clk                                                                                  ),
            .rst_n             ( rst_n                                                                                ),
            .row_sel           ( row_sel_inputReg                                                                     ),
            .WL                ( WL_inputReg[(i+1)*2-1:2*i]                                                           ),
            .BL                ( BL_inputReg[COLUMN_NUM*8-1:0]                                                        ),
            .NEG               ( NEG                                                                                  ),
            .ZERO              ( ZERO                                                                                 ),
            .R_ctrl            ( R_ctrl[COLUMN_NUM*8-1:0]                                                             ),
            .R_ctrl_b          ( R_ctrl_b[COLUMN_NUM*8-1:0]                                                           ),
            .mode              ( mode_inputReg                                                                        ),
            .sum               ( sum[(i+1)*ADDER_TREE_OUT_BITWIDTH*10-1:i*ADDER_TREE_OUT_BITWIDTH*10]                 ),
            .compensation_sum  ( compensation_sum[(i+1)*ADDER_TREE_OUT_BITWIDTH*2-1:i*ADDER_TREE_OUT_BITWIDTH*2]      )
        );
    end 
endgenerate

endmodule