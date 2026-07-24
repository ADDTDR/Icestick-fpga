module ht16k33 (
    input wire clk,
    input wire rst,

    // External payload memory interface.
    output wire [3:0] payload_addr,
    input wire [7:0] payload_data,

    // External I2C transmitter interface.
    output reg i2c_start,
    output wire [6:0] i2c_address,
    output wire [4:0] i2c_byte_count,
    output wire [7:0] i2c_tx_byte,
    input wire [4:0] i2c_byte_index,
    input wire i2c_busy,
    input wire i2c_done,
    input wire i2c_ack_error,

    output reg nack_seen
);
    localparam integer POWERUP_CYCLES = 1200000; // ~100 ms at 12 MHz
    localparam [6:0] HT16K33_ADDR = 7'h70;

    localparam [2:0] ST_POWERUP   = 3'd0;
    localparam [2:0] ST_START_MSG = 3'd1;
    localparam [2:0] ST_WAIT_MSG  = 3'd2;
    localparam [2:0] ST_NEXT_MSG  = 3'd3;
    localparam [2:0] ST_DONE      = 3'd4;

    reg [2:0] state = ST_POWERUP;
    reg [23:0] powerup_count = 24'd0;
    reg [1:0] msg_idx = 2'd0;

    function [4:0] payload_len;
        input [1:0] msg;
        begin
            case (msg)
                2'd0: payload_len = 5'd1;  // 0x21: oscillator on
                2'd1: payload_len = 5'd1;  // 0x81: display on, no blink
                2'd2: payload_len = 5'd1;  // 0xEE: brightness level 14
                2'd3: payload_len = 5'd17; // RAM pointer + 16 display bytes
                default: payload_len = 5'd1;
            endcase
        end
    endfunction

    function [7:0] payload_byte;
        input [1:0] msg;
        input [4:0] idx;
        begin
            payload_byte = 8'h00;
            case (msg)
                2'd0: payload_byte = 8'h21;
                2'd1: payload_byte = 8'h81;
                2'd2: payload_byte = 8'hEE;
                2'd3: begin
                    case (idx)
                        5'd0: payload_byte = 8'h00; // display RAM start address
                        5'd1: payload_byte = 8'h06; // '1'
                        5'd2: payload_byte = 8'h5B; // '2'
                        5'd3: payload_byte = 8'h4F; // '3'
                        5'd4: payload_byte = 8'h66; // '4'
                        5'd5: payload_byte = 8'h6D; // '5'
                        5'd6: payload_byte = 8'h7D; // '6'
                        5'd7: payload_byte = 8'h07; // '7'
                        5'd8: payload_byte = 8'h7F; // '8'
                        5'd9: payload_byte = 8'h6F; // '9'
                        default: payload_byte = 8'h00;
                    endcase
                end
            endcase
        end
    endfunction

    function [7:0] msg_tx_byte;
        input [1:0] msg;
        input [4:0] idx;
        begin
            if (msg == 2'd3 && idx != 5'd0) begin
                msg_tx_byte = payload_data;
            end else begin
                msg_tx_byte = payload_byte(msg, idx);
            end
        end
    endfunction

    assign i2c_address = HT16K33_ADDR;
    assign i2c_byte_count = payload_len(msg_idx);
    assign i2c_tx_byte = msg_tx_byte(msg_idx, i2c_byte_index);

    // Byte 0 in message 3 is RAM start address (0x00), so payload data starts at byte 1.
    assign payload_addr = (msg_idx == 2'd3 && i2c_byte_index != 5'd0)
        ? (i2c_byte_index - 5'd1)
        : 4'd0;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_POWERUP;
            powerup_count <= 24'd0;
            msg_idx <= 2'd0;
            i2c_start <= 1'b0;
            nack_seen <= 1'b0;
        end else begin
            i2c_start <= 1'b0;

            case (state)
                ST_POWERUP: begin
                    if (powerup_count < POWERUP_CYCLES) begin
                        powerup_count <= powerup_count + 24'd1;
                    end else begin
                        state <= ST_START_MSG;
                    end
                end

                ST_START_MSG: begin
                    if (!i2c_busy) begin
                        i2c_start <= 1'b1;
                        state <= ST_WAIT_MSG;
                    end
                end

                ST_WAIT_MSG: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            nack_seen <= 1'b1;
                        end
                        state <= ST_NEXT_MSG;
                    end
                end

                ST_NEXT_MSG: begin
                    if (msg_idx == 2'd3) begin
                        state <= ST_DONE;
                    end else begin
                        msg_idx <= msg_idx + 2'd1;
                        state <= ST_START_MSG;
                    end
                end

                ST_DONE: begin
                    // Hold final frame on the display.
                    state <= ST_DONE;
                end

                default: begin
                    state <= ST_POWERUP;
                end
            endcase
        end
    end
endmodule
