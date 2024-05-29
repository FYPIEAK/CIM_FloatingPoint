module xnor_sram_numx8 #(
    parameter COLUMN_NUM = 512
)(
    input                         clk       ,
    input                         rst_n     ,
    input                         WL        , 
    input      [COLUMN_NUM*8-1:0] BL        ,  
    input      [COLUMN_NUM*8-1:0] R_ctrl    ,
    input      [COLUMN_NUM*8-1:0] R_ctrl_b  ,
    input      [2:0]              mode      ,
    output reg [COLUMN_NUM*10-1:0] P        ,
    output reg [COLUMN_NUM-1:0]   Q_out
);

wire       [COLUMN_NUM*8 - 1:0]   BLb ;      
assign BLb = ~BL;

genvar j;
generate 
    for(j=0; j<COLUMN_NUM; j=j+1) begin: xnor_sram_x8_j
        xnor_sram_x8 u_xnor_sram_x8(
            .clk         ( clk                     ),
            .rst_n       ( rst_n                   ),
            .WL          ( WL                      ),
            .BL          ( BL[(j+1)*8-1:j*8]       ),
            .BLb         ( BLb[(j+1)*8-1:j*8]      ),
            .R_ctrl      ( R_ctrl[(j+1)*8-1:j*8]   ),
            .mode        ( mode[2:0]               ),
            .R_ctrl_b    ( R_ctrl_b[(j+1)*8-1:j*8] ),
            .P           ( P[(j+1)*10 -1:j*10]     ),
            .Q_out       ( Q_out[j]                )                
        );
    end
endgenerate

endmodule
