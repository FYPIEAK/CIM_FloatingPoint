module booth_compensation (
    input clk,
    input rst_n,
    input    [2:0]       code,

    output reg [1:0] compensation
);

always @(*) begin
    if (!rst_n) 
        compensation <= 2'b00;
    else if (code == 3'b110 )
        compensation <= 2'b10;
    else if (code == 3'b100)
        compensation <= 2'b01;
    else 
        compensation <= 2'b00;
end


endmodule