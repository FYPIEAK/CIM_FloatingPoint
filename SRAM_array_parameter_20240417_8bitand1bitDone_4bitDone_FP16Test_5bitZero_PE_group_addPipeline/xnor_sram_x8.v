module xnor_sram_x8 (
    input              clk      ,
    input              rst_n    ,
    input              WL       , 
    input      [7:0]   BL       ,  
    input      [7:0]   BLb      ,       
    input      [7:0]   R_ctrl   ,
    input      [7:0]   R_ctrl_b ,
    input      [2:0]   mode     ,
    output reg [9:0]   P        ,
    output             Q_out
);

wire [7:0] p_temp;
wire [7:0] Q;
genvar j;
generate 
    for(j=0; j<8; j=j+1) begin: xnor_sram_j
        xnor_sram u_xnor_sram(
            .clk               (clk         ), 
            .rst_n             (rst_n       ),
            .WL                (WL          ),
            .BL                (BL[j]       ), 
            .BLb               (BLb[j]      ), 
            .R_ctrl            (R_ctrl[j]   ), 
            .R_ctrl_b          (R_ctrl_b[j] ), 
            .Q                 (Q[j]        ), 
            .V_out             (p_temp[j]   )    
        );
    end
endgenerate

always @(*) begin
    if (mode == 3'b000) begin
        if ((R_ctrl == 8'b0000_0000)&& (R_ctrl_b == 8'b0000_0000)) 
            P = 10'b0;
        else if (R_ctrl_b == 8'b1111_1111) begin 
            if ((BLb == 8'b1111_1111) && !WL) 
                P = {!Q[7],p_temp[7:4],!Q[3],1'b0,p_temp[2:0],1'b0};
            else if ((BLb == 8'b0000_0000) && !WL) 
                P = {!Q[7],p_temp[7:4],1'b0,p_temp[3:0]};
            else 
                P = 10'b0;
        end
        else begin
            if ((BLb == 8'b1111_1111) && !WL) 
                P = {Q[7],p_temp[7:4],Q[3],1'b0,p_temp[2:0],1'b0};
            else if ((BLb == 8'b0000_0000) && !WL) 
                P = {Q[7],p_temp[7:4],Q[3],p_temp[3:0]};
            else 
                P = 10'b0;
        end
    end
    else if (mode == 3'b001) begin
        if ((R_ctrl == 8'b0000_0000)&& (R_ctrl_b == 8'b0000_0000)) 
            P = 10'b0;
        else if (R_ctrl_b == 8'b1111_1111) begin 
            if ((BLb == 8'b1111_1111) && !WL) 
                P = {p_temp[7:4],1'b0,p_temp[3:0],1'b0};
            else if ((BLb == 8'b0000_0000) && !WL) 
                P = {!Q[7],p_temp[7:4],!Q[3],p_temp[3:0]};
            else 
                P = 10'b0;
        end
        else begin
            if ((BLb == 8'b1111_1111) && !WL) 
                P = {p_temp[7:4],1'b0,p_temp[3:0],1'b0};
            else if ((BLb == 8'b0000_0000) && !WL) 
                P = {Q[7],p_temp[7:4],Q[3],p_temp[3:0]};
            else 
                P = 10'b0;
        end
    end
    else begin
        P = {1'b0,p_temp[7:4],1'b0,p_temp[3:0]};
    end
end

assign Q_out = Q[4];


endmodule
