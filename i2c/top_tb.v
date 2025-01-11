`timescale 1ns / 1ps
`define DUMPSTR(x) `"x.vcd`"
module top_tb;

    // Testbench signals
    reg CLK_tb;           // Simulated clock signal
    wire SCL_tb;          // Simulated SCL signal
    wire SDA_tb;          // Simulated SDA signal (inout)

    // Pull-up resistor simulation for SDA (required for I²C operation)
    reg sda_internal;     // Internal signal to drive SDA
    assign SDA_tb = sda_internal ? 1'bz : 1'b0; // Pull-up behavior (Z = high-impedance)

    // Instantiate the top module
    top uut (
        .CLK_i(CLK_tb),    // Connect simulated clock
        .SCL_PIN(SCL_tb),  // Connect simulated SCL
        .SDA_PIN(SDA_tb)   // Connect simulated SDA
    );

    // Clock generation
    initial begin
        CLK_tb = 1'b0;
        forever #41.67 CLK_tb = ~CLK_tb; // 12 MHz clock (period = 83.33 ns)
    end

    // Simulation control
    initial begin
        // Initialize the simulation
        sda_internal = 1'b1;  // Pull SDA high initially
        $display("Starting simulation...");

        // Simulate an I²C transaction
        #1000; // Wait for 1 µs

        // Simulate START condition
        $display("Simulating START condition...");
        sda_internal = 1'b0; // Drive SDA low while SCL is high
        #500; // Wait for 500 ns

        // Simulate HT16K33 address transmission (7-bit address: 0x70 + write bit)
        $display("Sending address 0x70...");
        send_i2c_byte(8'hE0); // Address with write bit (8-bit: 11100000)

        // Simulate STOP condition
        $display("Simulating STOP condition...");
        sda_internal = 1'b0; // Drive SDA low
        #500;
        sda_internal = 1'b1; // Release SDA (high)

        // End simulation
        #1000;

        $dumpfile(`DUMPSTR(`VCD_OUTPUT));
        $dumpvars(0, top_tb);
        $display("End of simulation");
        $display("Simulation complete.");
        $finish;
    end

    // Task to simulate sending an I²C byte
    task send_i2c_byte(input [7:0] data);
        integer i;
        begin
            for (i = 7; i >= 0; i = i - 1) begin
                // Set SDA to the current bit
                sda_internal = data[i];
                #250; // Wait for half a clock period
                // Toggle SCL high
                $display("Sending bit: %b", data[i]);
                #250;
            end
        end
    endtask




endmodule
