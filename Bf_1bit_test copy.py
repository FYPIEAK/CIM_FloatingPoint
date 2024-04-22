{
 "cells": [
  {
   "cell_type": "code",
   "execution_count": 1251,
   "metadata": {},
   "outputs": [],
   "source": [
    "import torch\n",
    "import numpy as np\n",
    "import matplotlib.pyplot as plt\n",
    "import struct"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1252,
   "metadata": {},
   "outputs": [],
   "source": [
    "\n",
    "# generate a,b\n",
    "def generate_vectors(n):\n",
    "    a_uniform_distribution = np.random.uniform(low=-1_0000, high=1_0000, size=(1, n)) \n",
    "    b_uniform_distribution = np.random.choice([0, 1], size=(n, 1))\n",
    "\n",
    "    return a_uniform_distribution, b_uniform_distribution"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1253,
   "metadata": {},
   "outputs": [],
   "source": [
    "#base\n",
    "def multiply_vectors(a,b):\n",
    "    a_bfloat16 = a.astype(np.float16)\n",
    "    result = np.dot(a_bfloat16, b)\n",
    "    return result"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1254,
   "metadata": {},
   "outputs": [],
   "source": [
    "#向量中元素转化为二进制操作\n",
    "def Modify_tensor(tensor):\n",
    "    bf_list = tensor.detach().numpy().tolist() # 转成numpy变量再转换成list    \n",
    "    binary_array = []\n",
    "\n",
    "    for bf_nums in bf_list:\n",
    "        for bf_num in bf_nums:\n",
    "            float_bytes = struct.pack('>f', bf_num)\n",
    "            byte_array = ''.join(f'{byte:08b}' for byte in float_bytes)\n",
    "            binary_array.append(byte_array)\n",
    "    return binary_array\n",
    "\n",
    "#将8位补码二进制字符串转换为整数\n",
    "def twos_complement_to_int(binary_str):\n",
    "    if binary_str == \"\":\n",
    "        return 0\n",
    "\n",
    "    if binary_str[0] == '1':\n",
    "        inverted = ''.join('1' if bit == '0' else '0' for bit in binary_str)  \n",
    "        int_value = int(inverted, 2) + 1  \n",
    "        return -int_value  \n",
    "    else:\n",
    "        return int(binary_str, 2)  "
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1275,
   "metadata": {},
   "outputs": [],
   "source": [
    "#ReDCIM\n",
    "def ReDCIM_multiply(a,b):\n",
    "    a_tensor = torch.from_numpy(a)\n",
    "    b_tensor = torch.from_numpy(b)\n",
    "    a_fp32 = a_tensor.float()\n",
    "    a_modified = Modify_tensor(a_fp32)\n",
    "\n",
    "    ##预对齐\n",
    "    a_exp = []\n",
    "    for number in a_modified:\n",
    "        extracted_part = number[1:9]\n",
    "        a_exp.append(extracted_part)\n",
    "    a_exp_int = [int(binary, 2) for binary in a_exp]\n",
    "    a_exp_max = max(a_exp_int)\n",
    "    a_difference = [a_exp_max - value for value in a_exp_int]\n",
    "    print(a_exp)\n",
    "\n",
    "    a_mantissa = []\n",
    "    for number in a_modified:\n",
    "        if number[0] == '1':\n",
    "            inverted_part ='0' + ''.join('1' if bit == '0' else '0' for bit in number[9:15]) #取反码\n",
    "            complement = format(int(inverted_part, 2) + 1, '07b') #取补码\n",
    "            extracted_part = number[0] + complement #加符号位\n",
    "        else:\n",
    "            extracted_part = number[0] + '1' + number[9:14]\n",
    "        a_mantissa.append(extracted_part)\n",
    "    print(a_mantissa)\n",
    "\n",
    "    a_shifted_mantissa_values = []\n",
    "    for mant, diff in zip(a_mantissa, a_difference):\n",
    "        sign = int(mant[0], 2) #将mantissa 的首位取为符号位，并转化为int类型\n",
    "        if diff > 0:\n",
    "            # shifted_value_binary = (sign * '1' if sign == 1 else '0') * diff + mant[:-diff] #str类型拼接\n",
    "            shifted_value_binary = ('1' if sign == 1 else '0') * diff + mant[:-diff] #str类型拼接\n",
    "            print(type(shifted_value_binary), shifted_value_binary)\n",
    "        else:\n",
    "            shifted_value_binary = mant\n",
    "        a_shifted_mantissa_values.append(shifted_value_binary)\n",
    "    print(a_shifted_mantissa_values)\n",
    "\n",
    "    product_mantissa_int = [(int(a[1:], 2) if a[0] == '0' else -int(a[1:], 2)+1) * (int(b[1:], 2) if b[0] == '0' else -int(b[1:], 2)+1) for a, b in zip(a_shifted_mantissa_values, b_tensor)]\n",
    "    # product_mantissa_int= [twos_complement_to_int(product) for product in product_mantissa]\n",
    "    sum_product_mantissa = sum(product_mantissa_int)\n",
    "    sign = 1 if sum_product_mantissa < 0 else 0\n",
    "    \n",
    "    combined_result = ((-1) ** sign) * (2 ** (a_exp_max - 127)) * sum_product_mantissa\n",
    "    return combined_result"
   ]
  },
  {
   "cell_type": "code",
   "execution_count": 1276,
   "metadata": {},
   "outputs": [
    {
     "name": "stdout",
     "output_type": "stream",
     "text": [
      "[[ 3230.50566744 -1533.41269518 -2796.56002783  5634.24414492]]\n",
      "[[1]\n",
      " [0]\n",
      " [1]\n",
      " [1]]\n",
      "Result standard:\n",
      " [[6070.]]\n",
      "['10001010', '10001001', '10001010', '10001011']\n",
      "['0110010', '10100001', '10101001', '0101100']\n",
      "<class 'str'> 0011001\n",
      "<class 'str'> 11101000\n",
      "<class 'str'> 11010100\n",
      "['0011001', '11101000', '11010100', '0101100']\n"
     ]
    },
    {
     "ename": "TypeError",
     "evalue": "int() can't convert non-string with explicit base",
     "output_type": "error",
     "traceback": [
      "\u001b[1;31m---------------------------------------------------------------------------\u001b[0m",
      "\u001b[1;31mTypeError\u001b[0m                                 Traceback (most recent call last)",
      "Cell \u001b[1;32mIn[1276], line 10\u001b[0m\n\u001b[0;32m      7\u001b[0m result_standard \u001b[38;5;241m=\u001b[39m multiply_vectors(a, b)\n\u001b[0;32m      8\u001b[0m \u001b[38;5;28mprint\u001b[39m(\u001b[38;5;124m\"\u001b[39m\u001b[38;5;124mResult standard:\u001b[39m\u001b[38;5;130;01m\\n\u001b[39;00m\u001b[38;5;124m\"\u001b[39m, result_standard)\n\u001b[1;32m---> 10\u001b[0m result_ReDCIM \u001b[38;5;241m=\u001b[39m \u001b[43mReDCIM_multiply\u001b[49m\u001b[43m(\u001b[49m\u001b[43ma\u001b[49m\u001b[43m,\u001b[49m\u001b[43m \u001b[49m\u001b[43mb\u001b[49m\u001b[43m)\u001b[49m\n\u001b[0;32m     11\u001b[0m \u001b[38;5;28mprint\u001b[39m(\u001b[38;5;124m\"\u001b[39m\u001b[38;5;124mResult ReDCIM:\u001b[39m\u001b[38;5;130;01m\\n\u001b[39;00m\u001b[38;5;124m\"\u001b[39m, result_ReDCIM)\n",
      "Cell \u001b[1;32mIn[1275], line 41\u001b[0m, in \u001b[0;36mReDCIM_multiply\u001b[1;34m(a, b)\u001b[0m\n\u001b[0;32m     38\u001b[0m     a_shifted_mantissa_values\u001b[38;5;241m.\u001b[39mappend(shifted_value_binary)\n\u001b[0;32m     39\u001b[0m \u001b[38;5;28mprint\u001b[39m(a_shifted_mantissa_values)\n\u001b[1;32m---> 41\u001b[0m product_mantissa_int \u001b[38;5;241m=\u001b[39m [(\u001b[38;5;28mint\u001b[39m(a[\u001b[38;5;241m1\u001b[39m:], \u001b[38;5;241m2\u001b[39m) \u001b[38;5;28;01mif\u001b[39;00m a[\u001b[38;5;241m0\u001b[39m] \u001b[38;5;241m==\u001b[39m \u001b[38;5;124m'\u001b[39m\u001b[38;5;124m0\u001b[39m\u001b[38;5;124m'\u001b[39m \u001b[38;5;28;01melse\u001b[39;00m \u001b[38;5;241m-\u001b[39m\u001b[38;5;28mint\u001b[39m(a[\u001b[38;5;241m1\u001b[39m:], \u001b[38;5;241m2\u001b[39m)\u001b[38;5;241m+\u001b[39m\u001b[38;5;241m1\u001b[39m) \u001b[38;5;241m*\u001b[39m (\u001b[38;5;28mint\u001b[39m(b[\u001b[38;5;241m1\u001b[39m:], \u001b[38;5;241m2\u001b[39m) \u001b[38;5;28;01mif\u001b[39;00m b[\u001b[38;5;241m0\u001b[39m] \u001b[38;5;241m==\u001b[39m \u001b[38;5;124m'\u001b[39m\u001b[38;5;124m0\u001b[39m\u001b[38;5;124m'\u001b[39m \u001b[38;5;28;01melse\u001b[39;00m \u001b[38;5;241m-\u001b[39m\u001b[38;5;28;43mint\u001b[39;49m\u001b[43m(\u001b[49m\u001b[43mb\u001b[49m\u001b[43m[\u001b[49m\u001b[38;5;241;43m1\u001b[39;49m\u001b[43m:\u001b[49m\u001b[43m]\u001b[49m\u001b[43m,\u001b[49m\u001b[43m \u001b[49m\u001b[38;5;241;43m2\u001b[39;49m\u001b[43m)\u001b[49m\u001b[38;5;241m+\u001b[39m\u001b[38;5;241m1\u001b[39m) \u001b[38;5;28;01mfor\u001b[39;00m a, b \u001b[38;5;129;01min\u001b[39;00m \u001b[38;5;28mzip\u001b[39m(a_shifted_mantissa_values, b_tensor)]\n\u001b[0;32m     42\u001b[0m \u001b[38;5;66;03m# product_mantissa_int= [twos_complement_to_int(product) for product in product_mantissa]\u001b[39;00m\n\u001b[0;32m     43\u001b[0m sum_product_mantissa \u001b[38;5;241m=\u001b[39m \u001b[38;5;28msum\u001b[39m(product_mantissa_int)\n",
      "\u001b[1;31mTypeError\u001b[0m: int() can't convert non-string with explicit base"
     ]
    }
   ],
   "source": [
    "#vectors\n",
    "n = 4\n",
    "a,b = generate_vectors(n)\n",
    "print(a)\n",
    "print(b)\n",
    "\n",
    "result_standard = multiply_vectors(a, b)\n",
    "print(\"Result standard:\\n\", result_standard)\n",
    "\n",
    "result_ReDCIM = ReDCIM_multiply(a, b)\n",
    "print(\"Result ReDCIM:\\n\", result_ReDCIM)"
   ]
  }
 ],
 "metadata": {
  "kernelspec": {
   "display_name": "env_1",
   "language": "python",
   "name": "python3"
  },
  "language_info": {
   "codemirror_mode": {
    "name": "ipython",
    "version": 3
   },
   "file_extension": ".py",
   "mimetype": "text/x-python",
   "name": "python",
   "nbconvert_exporter": "python",
   "pygments_lexer": "ipython3",
   "version": "3.12.1"
  }
 },
 "nbformat": 4,
 "nbformat_minor": 2
}
