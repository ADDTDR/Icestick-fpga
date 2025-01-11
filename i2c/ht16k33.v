module ht16k33 (
    input wire clk,              // System clock
    input wire rst,              // Reset signal
    output wire scl,             // I2C Clock
    inout wire sda               // I2C Data line
);
    // HT16K33 Base Address (7-bit)
    parameter HT16K33_ADDR = 7'h70;

    // States
    parameter IDLE = 4'b0000;
    parameter INIT_OSC = 4'b0001;
    parameter DISP_ON = 4'b0010;
    parameter SEND_DATA = 4'b0011;
    parameter WAIT = 4'b0100;

    reg [3:0] state;
    reg start;
    reg [6:0] address;
    reg rw;
    reg [7:0] data_in;
    wire busy;
    wire ack;

    // Instantiate the I²C Master
    i2c_master i2c_inst (
        .clk(clk),
        .rst(rst),
        .start(start),
        .address(address),
        .rw(rw),
        .data_in(data_in),
        .scl(scl),
        .sda(sda),
        .busy(busy),
        .ack(ack)
    );

    // FSM Logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            start <= 0;
            address <= 0;
            rw <= 0;
            data_in <= 0;
        end else begin
            case (state)
                IDLE: begin
                    if (!busy) begin
                        state <= INIT_OSC;
                    end
                end
                INIT_OSC: begin
                    if (!busy) begin
                        start <= 1;
                        address <= HT16K33_ADDR;
                        rw <= 0;
                        data_in <= 8'h21; // Oscillator on
                        state <= WAIT;
                    end
                end
                DISP_ON: begin
                    if (!busy) begin
                        start <= 1;
                        address <= HT16K33_ADDR;
                        rw <= 0;
                        data_in <= 8'h81; // Display on
                        state <= WAIT;
                    end
                end
                SEND_DATA: begin
                    if (!busy) begin
                        start <= 1;
                        address <= HT16K33_ADDR;
                        rw <= 0;
                        data_in <= 8'b10101010; // Example data
                        state <= WAIT;
                    end
                end
                WAIT: begin
                    if (!busy) begin
                        start <= 0;
                        state <= (state == INIT_OSC) ? DISP_ON :
                                 (state == DISP_ON) ? SEND_DATA : IDLE;
                    end
                end
            endcase
        end
    end
endmodule
