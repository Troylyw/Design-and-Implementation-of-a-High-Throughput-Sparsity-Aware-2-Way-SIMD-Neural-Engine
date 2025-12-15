import random

NUM_NEURONS = 10
NUM_INPUTS = 4
MIN_VAL = -128
MAX_VAL = 127
NUM_TEST_CASES = 5

def to_hex(val, bits=8):
    val = int(val)
    if val < 0:
        val = (1 << bits) + val
    return f"{val:02X}"

weights = []
print("Generating weights.hex...")
with open("weights.hex", "w") as f:
    for n in range(NUM_NEURONS):
        row = []
        for i in range(NUM_INPUTS):
            w = random.randint(-10, 10) 
            row.append(w)
            f.write(f"{to_hex(w)}\n")
        weights.append(row)

biases = []
print("Generating biases.hex...")
with open("biases.hex", "w") as f:
    for n in range(NUM_NEURONS):
        b = random.randint(-20, 20)
        biases.append(b)
        f.write(f"{to_hex(b)}\n")

inputs = []
print("Generating inputs.hex...")
with open("inputs.hex", "w") as f:
    for t in range(NUM_TEST_CASES):
        row = []
        for i in range(NUM_INPUTS):
            if t == 0 and i == 1:
                val = 0 
                print(f"  -> Injected ZERO at Case {t}, Input {i} for Waveform Visualization")
            
            elif random.random() < 0.1: 
                val = 0
            
            else:
                val = random.randint(-50, 50)
                if val == 0: val = 1 

            row.append(val)
            f.write(f"{to_hex(val)}\n")
        inputs.append(row)


print("Generating golden_outputs.hex...")
with open("golden_outputs.hex", "w") as f:
    for t in range(NUM_TEST_CASES):
        curr_input = inputs[t]
        for n in range(NUM_NEURONS):
            acc = 0
            for i in range(NUM_INPUTS):
                acc += curr_input[i] * weights[n][i]
            
            acc += biases[n]
            
            if acc < 0:
                res = 0
            elif acc > 127:
                res = 127
            else:
                res = acc
            
            f.write(f"{to_hex(res)}\n")

print("Done! All .hex files generated with Sparse patterns.")