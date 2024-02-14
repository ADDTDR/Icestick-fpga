from PIL import Image, ImageDraw
import time

width, height = 160, 80 

def generate_pattern(height=height, width=width, i = 0):
    image = Image.new("RGB", (width, height), 'white')
    draw = ImageDraw.Draw(image)
    
    for x in range(0, width):
        for y in range(0, height):


            x_bit_3 = (x >> i) & 1  # Extract the 4th bit of x
            y_bit_2 = (y >> i) & 1  # Extract the 3rd bit of y
            if x_bit_3 ^ y_bit_2:
                pattern1 = (0b00000 << 11) | (0b111111 << 5) | 0b00000  # Construct the pattern1 value
            else:
                pattern1 = (0b00000 << 11) | (0b000000 << 5) | 0b11111   # Construct the pattern1 value
   


            red =   (pattern1 & 0b1111100000000000) >> 11
            green = (pattern1 & 0b0000011111100000) >> 5
            blue =  (pattern1 & 0b0000000000011111) 


            # print('red', '{0:08b}'.format(red << 3))
            # print('green', '{0:08b}'.format(green << 2))
            # print('blue', '{0:08b}'.format(blue << 3))
            # print('\n')

            draw.rectangle([x, y, x+1, y+1], fill=(red << 3, green << 2, blue << 3))

    image.save('image.png')


def generate_pattern2(height=height, width=width, i = 0):
    image = Image.new("RGB", (width, height), 'white')
    draw = ImageDraw.Draw(image)
    for x in range(0, width):
        for y in range(0, height):

            red, blue, green = x-y-i, x-y-i, x-y-i
            draw.rectangle([x, y, x+1, y+1], fill=(red << 3, green << 2, blue << 3))

    image.save('image.png')


if __name__ == '__main__':
    for i in range(1, 100):
        generate_pattern2(i=i)
        time.sleep(0.1)