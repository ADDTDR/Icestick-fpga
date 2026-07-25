module ht16k33 (
    input wire clk,
    input wire rst,

    // External payload memory interface.
    output wire [3:0] payload_addr,
    input wire [7:0] payload_data,

    // External I2C transmitter interface.
    output reg i2c_start,
    output reg i2c_read,
    output wire [6:0] i2c_address,
    output wire [4:0] i2c_byte_count,
    output wire [7:0] i2c_tx_byte,
    input wire [4:0] i2c_byte_index,
    input wire i2c_busy,
    input wire i2c_done,
    input wire i2c_ack_error,
    input wire [7:0] i2c_rx_byte,
    input wire i2c_rx_valid,

    output reg nack_seen,
    output reg key_a_pressed
);
    localparam integer POWERUP_CYCLES = 1200000; // ~100 ms at 12 MHz
    localparam [6:0] HT16K33_ADDR = 7'h70;
    localparam [7:0] HT16K33_KEYDATA_ADDR = 8'h40;
    localparam integer KEY_POLL_CYCLES = 120000; // ~10 ms at 12 MHz

    localparam [3:0] ST_POWERUP        = 4'd0;
    localparam [3:0] ST_START_MSG      = 4'd1;
    localparam [3:0] ST_WAIT_MSG       = 4'd2;
    localparam [3:0] ST_NEXT_MSG       = 4'd3;
    localparam [3:0] ST_KEY_WAIT       = 4'd4;
    localparam [3:0] ST_KEYPTR_START   = 4'd5;
    localparam [3:0] ST_KEYPTR_WAIT    = 4'd6;
    localparam [3:0] ST_KEYREAD_START  = 4'd7;
    localparam [3:0] ST_KEYREAD_WAIT   = 4'd8;

    reg [3:0] state = ST_POWERUP;
    reg [23:0] powerup_count = 24'd0;
    reg [16:0] key_poll_count = 17'd0;
    reg [1:0] msg_idx = 2'd0;
    reg key_poll_phase = 1'b0;

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
        input key_phase;
        input [1:0] msg;
        input [4:0] idx;
        begin
            if (key_phase) begin
                msg_tx_byte = HT16K33_KEYDATA_ADDR;
            end else if (msg == 2'd3 && idx != 5'd0) begin
                msg_tx_byte = payload_data;
            end else begin
                msg_tx_byte = payload_byte(msg, idx);
            end
        end
    endfunction

    assign i2c_address = HT16K33_ADDR;
    assign i2c_byte_count = key_poll_phase ? (i2c_read ? 5'd6 : 5'd1) : payload_len(msg_idx);
    assign i2c_tx_byte = msg_tx_byte(key_poll_phase, msg_idx, i2c_byte_index);

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
            i2c_read <= 1'b0;
            nack_seen <= 1'b0;
            key_a_pressed <= 1'b0;
            key_poll_count <= 17'd0;
            key_poll_phase <= 1'b0;
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
                        i2c_read <= 1'b0;
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
                        key_poll_count <= 17'd0;
                        state <= ST_KEY_WAIT;
                    end else begin
                        msg_idx <= msg_idx + 2'd1;
                        state <= ST_START_MSG;
                    end
                end

                ST_KEY_WAIT: begin
                    if (key_poll_count < KEY_POLL_CYCLES) begin
                        key_poll_count <= key_poll_count + 17'd1;
                    end else begin
                        key_poll_count <= 17'd0;
                        key_poll_phase <= 1'b1;
                        state <= ST_KEYPTR_START;
                    end
                end

                ST_KEYPTR_START: begin
                    if (!i2c_busy) begin
                        i2c_read <= 1'b0;
                        i2c_start <= 1'b1;
                        state <= ST_KEYPTR_WAIT;
                    end
                end

                ST_KEYPTR_WAIT: begin
                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            nack_seen <= 1'b1;
                        end
                        state <= ST_KEYREAD_START;
                    end
                end

                ST_KEYREAD_START: begin
                    if (!i2c_busy) begin
                        i2c_read <= 1'b1;
                        i2c_start <= 1'b1;
                        state <= ST_KEYREAD_WAIT;
                    end
                end

                ST_KEYREAD_WAIT: begin
                    if (i2c_rx_valid && i2c_byte_index == 5'd4) begin
                        key_a_pressed <= i2c_rx_byte[4];
                    end

                    if (i2c_done) begin
                        if (i2c_ack_error) begin
                            nack_seen <= 1'b1;
                        end
                        i2c_read <= 1'b0;
                        key_poll_phase <= 1'b0;
                        state <= ST_KEY_WAIT;
                    end
                end

                default: begin
                    state <= ST_POWERUP;
                end
            endcase
        end
    end
endmodule
