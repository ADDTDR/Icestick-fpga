module i2c_master (
    input wire clk,              // System clock
    input wire rst,              // Reset signal
    input wire start,            // Start I2C transaction
    input wire [6:0] address,    // 7-bit I2C device address
    input wire rw,               // Read/Write bit (0 = Write, 1 = Read)
    input wire [7:0] data_in,    // Data to send (in write mode)
    output reg scl,              // I2C Clock
    inout wire sda,              // I2C Data line
    output reg busy,             // Busy flag
    output reg ack               // ACK received
);

    // State Machine States as Parameters
    parameter IDLE = 4'b0000;
    parameter START = 4'b0001;
    parameter SEND_ADDR = 4'b0010;
    parameter SEND_RW = 4'b0011;
    parameter SEND_DATA = 4'b0100;
    parameter WAIT_ACK = 4'b0101;
    parameter STOP = 4'b0110;

    reg [3:0] state;             // Current state
    reg [3:0] bit_counter;       // Bit counter for serial transmission
    reg sda_out;                 // Internal SDA line control
    reg sda_dir;                 // SDA direction (1 = output, 0 = input)
    reg scl_enable;              // SCL control for toggling clock

    assign sda = (sda_dir) ? sda_out : 1'bz; // High-Z for input mode

    // I2C Clock Divider (for SCL frequency)
    reg [15:0] clk_div;
    parameter CLK_DIV_MAX = 250; // Adjust for desired SCL speed
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            clk_div <= 0;
            scl <= 1;
        end else if (clk_div == CLK_DIV_MAX) begin
            clk_div <= 0;
            scl <= ~scl; // Toggle SCL
        end else begin
            clk_div <= clk_div + 1;
        end
    end

    // State Machine
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            busy <= 0;
            ack <= 0;
            bit_counter <= 0;
            sda_out <= 1;
            sda_dir <= 1;
            scl_enable <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    ack <= 0;
                    if (start) begin
                        busy <= 1;
                        state <= START;
                    end
                end
                START: begin
                    sda_out <= 0; // Start condition
                    sda_dir <= 1;
                    scl_enable <= 1;
                    state <= SEND_ADDR;
                    bit_counter <= 7;
                end
                SEND_ADDR: begin
                    sda_out <= address[bit_counter];
                    if (bit_counter == 0) state <= SEND_RW;
                    else bit_counter <= bit_counter - 1;
                end
                SEND_RW: begin
                    sda_out <= rw; // Send R/W bit
                    state <= WAIT_ACK;
                end
                WAIT_ACK: begin
                    sda_dir <= 0; // Switch to input for ACK
                    if (~scl) begin
                        ack <= ~sda; // Capture ACK
                        sda_dir <= 1; // Switch back to output
                        if (rw) state <= STOP; // Stop if read
                        else state <= SEND_DATA; // Otherwise, send data
                    end
                end
                SEND_DATA: begin
                    sda_out <= data_in[bit_counter];
                    if (bit_counter == 0) state <= STOP;
                    else bit_counter <= bit_counter - 1;
                end
                STOP: begin
                    sda_out <= 0; // Stop condition
                    sda_dir <= 1;
                    scl_enable <= 0;
                    state <= IDLE;
                    busy <= 0;
                end
            endcase
        end
    end
endmodule
