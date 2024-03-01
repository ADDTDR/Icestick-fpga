
## Project Description:

This set of instructions represents my exploration of Apio FPGA for Verilog and FPGA development. 
Step by step guide through the process of setting up Apio, configuring it.

### Overview:

- Explore Verilog and FPGA development using Apio.
- Utilizing the Icestick FPGA board with a Lattice FPGA.
- Following a structured step-by-step approach outlined in these instructions.
- Apio for managing the FPGA development workflow, along with other essential tools like GTKWave for simulation.

### About the Icestick FPGA Board:

The Icestick board, featuring a Lattice FPGA, serves as the cornerstone of this exploration. As I progress through the instructions, I'll be interacting with the board, running simulations, building projects, and ultimately uploading binaries to witness the tangible results of FPGA development.

### Intended Audience:

This guide is crafted for individuals eager to dive into FPGA development using Apio, with a specific focus on Verilog. Whether you are a beginner looking to learn the basics or an experienced developer seeking to expand your FPGA knowledge, this step-by-step exploration aims to provide a comprehensive understanding of the development process.


Include this description at the beginning or end of your Markdown document to provide context and set expectations for the readers.
### Installing Apio:

1. Visit the Apio documentation page: [Apio Installation](https://apiodoc.readthedocs.io/en/stable/source/installation.html)
2. Install Apio using the following command:
   ```
   pip install -U apio
   ```
   on MacOS also need to install 
   ```
   sudo pip3 install apio
   brew install scons
   ```

### Configuring for Linux Users (Ubuntu/Debian):

- If you're not the root user, add your username to the "dialout" group using the following command:
  ```
  sudo usermod -a -G dialout $USER
  ```

### Configuring Apio Drivers:

1. Enable FTDI drivers:
   ```
   apio drivers --ftdi-enable
   ```

### Installing Tools and Dependencies:

- Install all required tools:
   ```
   apio install --all
   ```

### Connecting and Checking Icestick:

1. Connect the Icestick board.
2. Verify the FTDI driver connection:
   ```
   apio system --lsftdi
   ```

### Managing Examples:

- List all available Apio examples:
   ```
   apio examples -l
   ```

- Clone an example (e.g., Icestick LEDs):
   ```
   apio examples -d icestick/leds
   ```

### Exploring suported Boards:

- List all Superted boards:
   ```
   apio boards --list
   ```

### Initializing and Verifying Design:

1. Select the Icestick board:
   ```
   apio init --board icestick
   ```

2. Verify the design:
   ```
   apio verify
   ```

### Simulation and Building:

- Install GTKWave if not already installed:
   ```
   sudo apt install gtkwave
   ```

- Simulate the project:
   ```
   apio sim
   ```

- Build the project:
   ```
   apio build
   ```

### Uploading Binaries to the Board:

- Upload the binaries to the Icestick board:
   ```
   apio upload
   ```
