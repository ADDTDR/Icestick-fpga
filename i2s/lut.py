import math

LUT_SIZE = 256
AMPLITUDE = 32767 / 6 # max for signed 16-bit

print("module sine_rom (")
print("    input  wire [7:0] addr,")
print("    output reg  signed [15:0] data")
print(");")
print("always @(*) begin")
print("    case (addr)")

for i in range(LUT_SIZE):
    angle = 2.0 * math.pi * i / LUT_SIZE
    value = int(round(AMPLITUDE * math.sin(angle)))
    if value > 0:
        str = f"        8'd{i}: data = 16'sd{value};"
    else: 
        str = f"        8'd{i}: data = -16'sd{value*-1};"
        # str.replace("= ", "= -")
    print(str)

print("        default: data = 16'sd0;")
print("    endcase")
print("end")
print("endmodule")
