module adder_tree (
    input               clk     ,
    input               rst_n   ,
    input       [127:0] adder   ,
    output reg  [7:0]   sum
);
 
reg [7:0] sum_preReg1; 
reg [7:0] sum_preReg2; 
always @(posedge clk or negedge rst_n) begin 
    if (!rst_n) begin
        sum_preReg1 <= 8'b0;
        sum_preReg2 <= 8'b0;
        sum <= 8'b0;
    end
    else begin
        sum_preReg1 <= adder[0]+ adder[1]+ adder[2]+ adder[3]+ adder[4]+ adder[5]+ adder[6]+ adder[7]+ adder[8]+ adder[9]+ adder[10]+ adder[11]+ adder[12]+ adder[13]+ adder[14]+ adder[15]+ adder[16]+ adder[17]+ adder[18]+ adder[19]+ adder[20]+ adder[21]+ adder[22]+ adder[23]+ adder[24]+ adder[25]+ adder[26]+ adder[27]+ adder[28]+ adder[29]+ adder[30]+ adder[31]+ adder[32]+ adder[33]+ adder[34]+ adder[35]+ adder[36]+ adder[37]+ adder[38]+ adder[39]+ adder[40]+ adder[41]+ adder[42]+ adder[43]+ adder[44]+ adder[45]+ adder[46]+ adder[47]+ adder[48]+ adder[49]+ adder[50]+ adder[51]+ adder[52]+ adder[53]+ adder[54]+ adder[55]+ adder[56]+ adder[57]+ adder[58]+ adder[59]+ adder[60]+ adder[61]+ adder[62]+ adder[63]+ adder[64]+ adder[65]+ adder[66]+ adder[67]+ adder[68]+ adder[69]+ adder[70]+ adder[71]+ adder[72]+ adder[73]+ adder[74]+ adder[75]+ adder[76]+ adder[77]+ adder[78]+ adder[79]+ adder[80]+ adder[81]+ adder[82]+ adder[83]+ adder[84]+ adder[85]+ adder[86]+ adder[87]+ adder[88]+ adder[89]+ adder[90]+ adder[91]+ adder[92]+ adder[93]+ adder[94]+ adder[95]+ adder[96]+ adder[97]+ adder[98]+ adder[99]+ adder[100]+ adder[101]+ adder[102]+ adder[103]+ adder[104]+ adder[105]+ adder[106]+ adder[107]+ adder[108]+ adder[109]+ adder[110]+ adder[111]+ adder[112]+ adder[113]+ adder[114]+ adder[115]+ adder[116]+ adder[117]+ adder[118]+ adder[119]+ adder[120]+ adder[121]+ adder[122]+ adder[123]+ adder[124]+ adder[125]+ adder[126]+ adder[127];
        sum_preReg2 <= sum_preReg1;
        sum <= sum_preReg2;
    end
end
 
endmodule
