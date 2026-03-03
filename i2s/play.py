import math
import wave
import struct

# Parameters
fs = 44100          # Sampling rate (Hz)
f = 550             # Frequency (Hz)
duration = 3        # seconds
period_samples = 882  # Exact repetition period

# Generate one exact discrete period
one_period = []
for n in range(period_samples):
    value = math.sin(2 * math.pi * f * n / fs)
    v_16 = value * 32767
    vs = int(v_16/20)
    one_period.append(vs)

# Total samples for 3 seconds
total_samples = int(fs * duration)

with open("mem_init.txt", "w+") as file:
    for i in one_period:
        
        file.write(f"{i & 0xFFFF:04x}\n")

# # Repeat the period to fill 3 seconds
# signal = []
# while len(signal) < total_samples:
#     signal.extend(one_period)

# # Trim to exact length
# signal = signal[:total_samples]

# # Convert to 16-bit integers
# signal_int16 = [sample  for sample in signal]

# # Write WAV file
# with wave.open("550Hz_periodic.wav", "w") as wav_file:
#     wav_file.setnchannels(1)     # Mono
#     wav_file.setsampwidth(2)     # 16-bit
#     wav_file.setframerate(fs)
    
#     for sample in signal_int16:
#         wav_file.writeframes(struct.pack('<h', sample))

# print("WAV file created: 550Hz_periodic.wav")