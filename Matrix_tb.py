import numpy as np
s = 32  
matrix =  np.random.uniform(-10, 10, (2 * s, s)).astype(np.float32)
np.savetxt("D:/E/STUDY/competition/0403/LoongArch-Processing-System/1C102/testbench/matrix.txt", matrix, fmt='%f') 

int_repr = np.frombuffer(matrix.tobytes(), dtype=np.uint32)
hex_repr = np.vectorize(hex)(int_repr)
hex_matrix = hex_repr.reshape(2 * s, s)

with open("D:/E/STUDY/competition/0403/LoongArch-Processing-System/1C102/testbench/hex_matrix.txt", 'w') as file:
    for row in hex_matrix:
        for col in row:
            s = str(col)[2:]
            print(s, file=file, end="\n")
