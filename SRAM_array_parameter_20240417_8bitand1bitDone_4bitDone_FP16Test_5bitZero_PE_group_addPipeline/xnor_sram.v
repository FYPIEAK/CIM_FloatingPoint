module xnor_sram(
    input          clk       ,
    input          rst_n     ,
    input          WL        ,
    input          BL        ,
    input          BLb       ,
    input          R_ctrl    ,
    input          R_ctrl_b  ,
    output reg     V_out     ,
    output reg     Q
);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)
        Q <= 1'b0;
    else if(WL) begin
        Q <= BL ;
    end
end

always @(*) begin
    if (!rst_n) 
        V_out = 1'b0;
    else if(WL) 
        V_out = 1'b0;
    else 
        V_out = Q ^ R_ctrl_b;
end


endmodule
