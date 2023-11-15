import itertools

# part(a)

def find_out_delay(x):
    if (out_delay_evaluated[x]):
        return out_delay[x]
    else:
        y = find_out_delay(out_circuit_graph[x][0])
        for i in out_circuit_graph[x][1:]:
            if (y < find_out_delay(i)):
                y = out_delay[i]
        out_delay[x] = y+gate_delays[out_generator_gate[x]]
        out_delay_evaluated[x] = True
        return out_delay[x]

gate_delays_file = open("gate_delays.txt", "r")
parse = []
parse_len = 0
gate_delays = {}
for line in gate_delays_file.readlines():
    if (line[0:2] == '//'):
        continue
    i = 0
    while (line[i] != '\n'):
        str_buffer = ''
        while (line[i] == ' '):
            i += 1
        while (line[i] != ' ' and line[i] != '\n'):
            str_buffer += line[i]
            i += 1
        if (str_buffer != ''):
            parse.append(str_buffer)
            parse_len += 1
i = 0
while (i < parse_len):
    gate_delays[parse[i]] = float(parse[i+1])
    i += 2

print(gate_delays)

primary_inputs = []
primary_outputs = []
internal_signals = []
out_circuit_graph = {}
out_generator_gate = {}
out_delay_evaluated = {}
out_delay = {}
circuit_file = open("circuit.txt", "r")
parse = []
parse_len = 0

for line in circuit_file.readlines():
    if (line[0:2] == '//'):
        continue
    i = 0
    while (line[i] != '\n'):
        str_buffer = ''
        while (line[i] == ' '):
            i += 1
        while (line[i] != ' ' and line[i] != '\n'):
            str_buffer += line[i]
            i += 1
        if (str_buffer != ''):
            parse.append(str_buffer)
            parse_len += 1

i = 0
key = ['PRIMARY_INPUTS', 'PRIMARY_OUTPUTS',
       'INTERNAL_SIGNALS', 'INV', 'OR2', 'AND2', 'NOR2', 'NAND2']

while (i < parse_len):
    if (parse[i] == 'PRIMARY_INPUTS'):
        j = i+1
        while ((parse[j] not in key) and j < parse_len):
            primary_inputs.append(parse[j])
            out_delay_evaluated[parse[j]] = True
            out_delay[parse[j]] = 0
            j = j+1
        i = j
    elif (parse[i] == 'PRIMARY_OUTPUTS'):
        j = i+1
        while ((parse[j] not in key) and j < parse_len):
            primary_outputs.append(parse[j])
            out_delay_evaluated[parse[j]] = False
            out_delay[parse[j]] = None
            j = j+1
        i = j
    elif (parse[i] == 'INTERNAL_SIGNALS'):
        j = i+1
        while ((parse[j] not in key) and j < parse_len):
            internal_signals.append(parse[j])
            out_delay_evaluated[parse[j]] = False
            out_delay[parse[j]] = None
            j = j+1
        i = j
    elif (parse[i] == 'INV'):
        out_circuit_graph[parse[i+2]] = (parse[i+1])
        out_generator_gate[parse[i+2]] = 'INV'
        i = i+3
    elif (parse[i] == 'OR2'):
        out_circuit_graph[parse[i+3]] = (parse[i+1], parse[i+2])
        out_generator_gate[parse[i+3]] = 'OR2'
        i = i+4
    elif (parse[i] == 'AND2'):
        out_circuit_graph[parse[i+3]] = (parse[i+1], parse[i+2])
        out_generator_gate[parse[i+3]] = 'AND2'
        i = i+4
    elif (parse[i] == 'NOR2'):
        out_circuit_graph[parse[i+3]] = (parse[i+1], parse[i+2])
        out_generator_gate[parse[i+3]] = 'NOR2'
        i = i+4
    else:
        out_circuit_graph[parse[i+3]] = (parse[i+1], parse[i+2])
        out_generator_gate[parse[i+3]] = 'NAND2'
        i = i+4

res = []
for i in primary_outputs:
    temp = find_out_delay(i)
    if (temp.is_integer()):
        temp = int(temp)
    res.append(i+" "+str(temp)+'\n')

output_delays_file = open("output_delays.txt", "w")
output_delays_file.writelines(res)

# part(b)

in_circuit_graph = {}
in_generator_gate = {}
in_delay_evaluated = {}
in_delay = {}

for i in primary_inputs:
    in_circuit_graph[i] = []
    in_generator_gate[i] = []
    in_delay_evaluated[i] = False
    in_delay[i] = None
for i in internal_signals:
    in_circuit_graph[i] = []
    in_generator_gate[i] = []
    in_delay_evaluated[i] = False
    in_delay[i] = None
for key in out_circuit_graph:
    for value in out_circuit_graph[key]:
        in_circuit_graph[value].append(key)
        in_generator_gate[value].append(out_generator_gate[key])

required_delays_file = open("required_delays.txt", "r")
parse = []
parse_len = 0
for line in required_delays_file.readlines():
    if (line[0:2] == '//'):
        continue
    i = 0
    while (line[i] != '\n'):
        str_buffer = ''
        while (line[i] == ' '):
            i += 1
        while (line[i] != ' ' and line[i] != '\n'):
            str_buffer += line[i]
            i += 1
        if (str_buffer != ''):
            parse.append(str_buffer)
            parse_len += 1

i = 0
while (i < parse_len):
    in_delay_evaluated[parse[i]] = True
    in_delay[parse[i]] = float(parse[i+1])
    i += 2

def find_in_delay(x):
    if (in_delay_evaluated[x]):
        return in_delay[x]
    else:
        y = find_in_delay(in_circuit_graph[x][0]) - \
            gate_delays[in_generator_gate[x][0]]
        for (sig, gate) in zip(in_circuit_graph[x][1:], in_generator_gate[x][1:]):
            temp = find_in_delay(sig)-gate_delays[gate]
            if y > temp:
                y = temp
        in_delay[x] = y
        in_delay_evaluated[x] = True
        return y

res = []
for i in primary_inputs:
    temp = find_in_delay(i)
    if (temp.is_integer()):
        temp = int(temp)
    res.append(i+" "+str(temp)+'\n')

input_delays_file = open("input_delays.txt", "w")
input_delays_file.writelines(res)