module R_ctrl_generate (
    input  ZERO,
    input  NEG,
    input  [7:0] activations,
    input  [2:0] mode,


    output reg [7:0] R_ctrl,
    output reg [7:0] R_ctrl_b
);

always @(*) begin
    if (mode == 3'b000 || mode == 3'b001) begin
        if (ZERO) begin
            R_ctrl = 8'b0000_0000;
            R_ctrl_b = 8'b0000_0000;
        end
        else if (NEG) begin
            R_ctrl = 8'b0000_0000;
            R_ctrl_b = 8'b1111_1111;
        end
        else begin
            R_ctrl = 8'b1111_1111;
            R_ctrl_b = 8'b0000_0000;
        end
    end
    else begin
        R_ctrl_b = activations[7:0];
        R_ctrl = ~activations[7:0];
    end
end

endmodule