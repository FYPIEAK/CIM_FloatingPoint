module PE #(
    parameter COLUMN_NUM = 256,
    parameter ADDER_TREE_OUT_BITWIDTH = 9
)(
    input                                          clk                   ,
    input                                          rst_n                 ,
    input                                          row_sel               , // row_sel = 1, ROW1 will be selected; row_sel = 0,ROW0 will be selected;
    input      [1:0]                               WL                    , 
    input      [COLUMN_NUM*8 - 1:0]                BL                    ,
    input      [COLUMN_NUM-1:0]                    NEG                   ,
    input      [COLUMN_NUM-1:0]                    ZERO                  ,
    input      [COLUMN_NUM*8-1:0]                  R_ctrl                ,
    input      [COLUMN_NUM*8-1:0]                  R_ctrl_b              ,  
    input      [2:0]                               mode                  , // mode = 000, 8bit x 8bit; mode = 001, 4bit x 4bit; mode = 010, 1bit x 1bit; mode = 100, FP16 x 1bit;
    
    output reg [ADDER_TREE_OUT_BITWIDTH*10 - 1:0]  sum                   ,
    output reg [2*ADDER_TREE_OUT_BITWIDTH - 1:0]   compensation_sum
);




// *********************** compensation generate **************************
wire [COLUMN_NUM*3-1:0] code;
genvar i;
generate 
    for (i=0 ; i<COLUMN_NUM ; i=i+1) begin: code_i
        assign code[(i+1)*3-1:3*i] = {NEG[i],~BL[i*8],ZERO[i]}; 
    end 
endgenerate

genvar j;
wire [COLUMN_NUM*2-1:0] compensation;
generate 
    for(j=0; j<COLUMN_NUM; j=j+1) begin: booth_compensation_j
        booth_compensation u_booth_compensation(
            .clk    ( clk                  ),
            .rst_n  ( rst_n                ),
            .code   ( code[(j+1)*3-1:3*j]  ),
            .compensation  ( compensation[(j+1)*2-1:2*j]  )
        );
    end
endgenerate
// *********************** compensation generate **************************



// ***********************  SRAM ROW0 **************************
wire [COLUMN_NUM*10-1:0] p_temp_row0;
wire [COLUMN_NUM-1:0] Q_out_row0;
xnor_sram_numx8#(
    .COLUMN_NUM (COLUMN_NUM)
) u_xnor_sram_row0(
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .WL         ( WL[0]     ),
    .BL         ( BL        ),
    .R_ctrl     ( R_ctrl    ),
    .R_ctrl_b   ( R_ctrl_b  ),
    .mode       ( mode      ),
    .P          ( p_temp_row0    ),
    .Q_out      ( Q_out_row0)
);

wire  [COLUMN_NUM-1:0] adder_0_row0;
wire  [COLUMN_NUM-1:0] adder_1_row0;
wire  [COLUMN_NUM-1:0] adder_2_row0;
wire  [COLUMN_NUM-1:0] adder_3_row0;
wire  [COLUMN_NUM-1:0] adder_4_row0;
wire  [COLUMN_NUM-1:0] adder_5_row0;
wire  [COLUMN_NUM-1:0] adder_6_row0;
wire  [COLUMN_NUM-1:0] adder_7_row0;
wire  [COLUMN_NUM-1:0] adder_8_row0;
wire  [COLUMN_NUM-1:0] adder_9_row0;

wire [COLUMN_NUM*10-1:0] adder_row0;

generate 
    for (i=0 ; i<COLUMN_NUM ; i=i+1) begin: adder_row0_generate_i
        assign adder_0_row0[i] = p_temp_row0[i*10]; 
        assign adder_1_row0[i] = p_temp_row0[i*10 + 1]; 
        assign adder_2_row0[i] = p_temp_row0[i*10 + 2]; 
        assign adder_3_row0[i] = p_temp_row0[i*10 + 3]; 
        assign adder_4_row0[i] = p_temp_row0[i*10 + 4]; 
        assign adder_5_row0[i] = p_temp_row0[i*10 + 5]; 
        assign adder_6_row0[i] = p_temp_row0[i*10 + 6]; 
        assign adder_7_row0[i] = p_temp_row0[i*10 + 7]; 
        assign adder_8_row0[i] = p_temp_row0[i*10 + 8]; 
        assign adder_9_row0[i] = p_temp_row0[i*10 + 9]; 
    end 
endgenerate

assign adder_row0 = {adder_9_row0,adder_8_row0,adder_7_row0,adder_6_row0,adder_5_row0,adder_4_row0,adder_3_row0,adder_2_row0,adder_1_row0,adder_0_row0};

// ***********************  SRAM ROW0 **************************



// ***********************  SRAM ROW1 **************************
wire [COLUMN_NUM*10-1:0] p_temp_row1;
wire [COLUMN_NUM-1:0] Q_out_row1;
xnor_sram_numx8#(
    .COLUMN_NUM (COLUMN_NUM)
) u_xnor_sram_row1(
    .clk        ( clk       ),
    .rst_n      ( rst_n     ),
    .WL         ( WL[1]     ),
    .BL         ( BL        ),
    .R_ctrl     ( R_ctrl    ),
    .R_ctrl_b   ( R_ctrl_b  ),
    .mode       ( mode      ),
    .P          ( p_temp_row1 ),
    .Q_out      ( Q_out_row1     )
);

wire  [COLUMN_NUM-1:0] adder_0_row1;
wire  [COLUMN_NUM-1:0] adder_1_row1;
wire  [COLUMN_NUM-1:0] adder_2_row1;
wire  [COLUMN_NUM-1:0] adder_3_row1;
wire  [COLUMN_NUM-1:0] adder_4_row1;
wire  [COLUMN_NUM-1:0] adder_5_row1;
wire  [COLUMN_NUM-1:0] adder_6_row1;
wire  [COLUMN_NUM-1:0] adder_7_row1;
wire  [COLUMN_NUM-1:0] adder_8_row1;
wire  [COLUMN_NUM-1:0] adder_9_row1;

wire [COLUMN_NUM*10-1:0] adder_row1;


generate 
    for (i=0 ; i<COLUMN_NUM ; i=i+1) begin: adder_row1_generate_i
        assign adder_0_row1[i] = p_temp_row1[i*10]; 
        assign adder_1_row1[i] = p_temp_row1[i*10 + 1]; 
        assign adder_2_row1[i] = p_temp_row1[i*10 + 2]; 
        assign adder_3_row1[i] = p_temp_row1[i*10 + 3]; 
        assign adder_4_row1[i] = p_temp_row1[i*10 + 4]; 
        assign adder_5_row1[i] = p_temp_row1[i*10 + 5]; 
        assign adder_6_row1[i] = p_temp_row1[i*10 + 6]; 
        assign adder_7_row1[i] = p_temp_row1[i*10 + 7]; 
        assign adder_8_row1[i] = p_temp_row1[i*10 + 8]; 
        assign adder_9_row1[i] = p_temp_row1[i*10 + 9]; 
    end 
endgenerate

assign adder_row1 = {adder_9_row1,adder_8_row1,adder_7_row1,adder_6_row1,adder_5_row1,adder_4_row1,adder_3_row1,adder_2_row1,adder_1_row1,adder_0_row1};

// ***********************  SRAM ROW0 **************************


// ***********************  SELECT RESULT FROM SRAM ROW1 OR SRAM ROW2 TO ADDER TREE **************************
wire [COLUMN_NUM*10-1:0] adder;
assign adder = row_sel?adder_row1:adder_row0;
// ***********************  SELECT RESULT FROM SRAM ROW1 OR SRAM ROW2 TO ADDER TREE **************************


// *********************** ADDER TREE OF PP **************************
generate 
    for(j=0; j<10; j=j+1) begin: adder_tree_j
        adder_tree u_adder_tree(
            .clk    ( clk                       ),
            .rst_n  ( rst_n                     ),
            .adder  ( adder[(j+1)*COLUMN_NUM-1:j*COLUMN_NUM]  ),
            .sum    ( sum[(j+1)*ADDER_TREE_OUT_BITWIDTH-1:j*ADDER_TREE_OUT_BITWIDTH]      )
        );
    end
endgenerate
// *********************** ADDER TREE OF PP **************************



// *********************** ADDER TREE OF Compensation **************************
wire [COLUMN_NUM -1:0] compensation_adder0_temp;
wire [COLUMN_NUM -1:0] compensation_adder1_temp;
wire [COLUMN_NUM -1:0] compensation_adder0;
wire [COLUMN_NUM -1:0] compensation_adder1;
generate 
    for (i=0 ; i<COLUMN_NUM ; i=i+1) begin: compensation_adder_i
        assign compensation_adder0_temp[i] = compensation[2*i];
        assign compensation_adder1_temp[i] = compensation[2*i+1]; 
    end 
endgenerate


assign compensation_adder0 = (mode == 3'b100)?Q_out_row0:compensation_adder0_temp;
assign compensation_adder1 = (mode == 3'b100)?Q_out_row1:compensation_adder1_temp;


adder_tree u_adder_tree_compensation0(
    .clk    ( clk                       ),
    .rst_n  ( rst_n                     ),
    .adder  ( compensation_adder0       ),
    .sum    ( compensation_sum[ADDER_TREE_OUT_BITWIDTH-1:0]     )
);

adder_tree u_adder_tree_compensation1(
    .clk    ( clk                       ),
    .rst_n  ( rst_n                     ),
    .adder  ( compensation_adder1       ),
    .sum    ( compensation_sum[ADDER_TREE_OUT_BITWIDTH*2-1:ADDER_TREE_OUT_BITWIDTH]   )
);
// *********************** ADDER TREE OF Compensation **************************

endmodule