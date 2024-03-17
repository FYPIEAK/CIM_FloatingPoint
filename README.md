# CIM_FloatingPoint
按照ReDCIM的逻辑写ReDCIM中，为了方便验证，先把size设置为2，表示一个1\*2的向量和2\*1的向量相乘的结果，如果需要其他大小，应该可以直接修改size。

验证结果在tb中。

verilog的结果较python有更大差异，主要原因是verilog是将结果转出为FP16格式再比较，而python计算后保留所有精度直接与原值比较
