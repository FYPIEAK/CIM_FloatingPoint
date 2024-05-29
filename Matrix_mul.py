import numpy as np

def read_and_multiply_matrices(filename, s):
    with open(filename, 'r') as file:
        data = file.read().split()
    data = list(map(float, data))
    
    matrix_A = data[:s*s]
    matrix_B = data[s*s:2*s*s]

    matrix_A = np.array(matrix_A).reshape(s, s)
    matrix_B = np.array(matrix_B).reshape(s, s)

    result_matrix = np.dot(matrix_A, matrix_B)

    with open('D:/E/STUDY/competition/0403/LoongArch-Processing-System/1C102/testbench/result.txt', 'w') as result_file:
        for row in result_matrix:
            result_file.write(' '.join(map(str, row)) + '\n')

s = 32
read_and_multiply_matrices('D:/E/STUDY/competition/0403/LoongArch-Processing-System/1C102/testbench/matrix.txt', s)  