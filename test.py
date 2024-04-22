import torch
import numpy as np
import matplotlib.pyplot as plt
import struct

# generate a,b
def generate_vectors(n):
    a_uniform_distribution = np.random.uniform(low=-1_0000, high=1_0000, size=(1, n)) 
    b_uniform_distribution = np.random.choice([0, 1], size=(n, 1))

    return a_uniform_distribution, b_uniform_distribution

#base
def multiply_vectors(a,b):
    a_bfloat16 = a.astype(np.float16)
    result = np.dot(a_bfloat16, b)
    return result

#向量中元素转化为二进制操作
def Modify_tensor(tensor):
    bf_list = tensor.detach().numpy().tolist() # 转成numpy变量再转换成list    
    binary_array = []

    for bf_nums in bf_list:
        for bf_num in bf_nums:
            float_bytes = struct.pack('>f', bf_num)
            byte_array = ''.join(f'{byte:08b}' for byte in float_bytes)
            binary_array.append(byte_array)
    return binary_array

    #ReDCIM
def ReDCIM_multiply(a,b):
    a_tensor = torch.from_numpy(a)
    b_tensor = torch.from_numpy(b)
    a_fp32 = a_tensor.float()
    a_modified = Modify_tensor(a_fp32)

    ##预对齐
    a_exp = []
    for number in a_modified:
        extracted_part = number[1:9]
        a_exp.append(extracted_part)
    a_exp_int = [int(binary, 2) for binary in a_exp]
    a_exp_max = max(a_exp_int)
    a_difference = [a_exp_max - value for value in a_exp_int]
    print(a_exp)

    a_mantissa = []
    for number in a_modified:
        a_mantissa.append(int('1' + number[9:15], 2) if number[0] == '0' else -int('1' + number[9:15], 2))
    print(a_mantissa)

    a_shifted_mantissa_values = []
    for mant, diff in zip(a_mantissa, a_difference):
        a_shifted_mantissa_values.append(mant >> diff)
    print(a_shifted_mantissa_values)
    product_mantissa_int = [a * b for a, b in zip(a_shifted_mantissa_values, b_tensor)]
    sum_product_mantissa = sum(product_mantissa_int)

    left_shift = a_exp_max - 127 - 6

    combined_result = sum_product_mantissa << left_shift if left_shift > 0 else sum_product_mantissa >> -left_shift
    return combined_result


#vectors
n = 20
a,b = generate_vectors(n)
print(a)
print(b)

result_standard = multiply_vectors(a, b)
print("Result standard:\n", result_standard)

result_ReDCIM = ReDCIM_multiply(a, b)
print("Result ReDCIM:\n", result_ReDCIM)
