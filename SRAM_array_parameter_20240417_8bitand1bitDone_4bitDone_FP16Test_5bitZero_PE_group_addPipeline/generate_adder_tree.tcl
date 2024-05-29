set bit_num 128
set outBit_num 8

set fp [open "adder_tree.v" "w"]
set output "        sum_preReg1 <= "
for {set i 0} {$i < $bit_num} {incr i} {
    if {$i == 0} {
        append output "adder\[$i\]"
    } elseif {$i == [expr $bit_num - 1]} {
        append output "+ adder\[$i\];"
    } else {
        append output "+ adder\[$i\]"
    }
}
puts $fp "module adder_tree ("
puts $fp "    input               clk     ,"
puts $fp "    input               rst_n   ,"
puts $fp "    input       \[[expr $bit_num - 1]:0\] adder   ,"
puts $fp "    output reg  \[[expr $outBit_num -1 ]:0\]   sum"
puts $fp ");"
puts $fp " "
puts $fp "reg \[[expr $outBit_num -1 ]:0\] sum_preReg1; "
puts $fp "reg \[[expr $outBit_num -1 ]:0\] sum_preReg2; "
puts $fp "always @(posedge clk or negedge rst_n) begin "
puts $fp "    if (!rst_n) begin"
puts $fp "        sum_preReg1 <= $outBit_num'b0;"
puts $fp "        sum_preReg2 <= $outBit_num'b0;"
puts $fp "        sum <= $outBit_num'b0;"
puts $fp "    end"
puts $fp "    else begin"
puts $fp $output
puts $fp "        sum_preReg2 <= sum_preReg1;"
puts $fp "        sum <= sum_preReg2;"
puts $fp "    end"
puts $fp "end"
puts $fp " "    
puts $fp "endmodule"

close $fp
