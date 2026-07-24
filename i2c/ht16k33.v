module ht16k33 (
    input wire clk,              // System clock
    input wire rst,              // Reset signal
    output wire scl,             // I2C Clock
    inout wire sda               // I2C Data line
);
    // 12 MHz input clock and ~100 kHz I2C clock generation.
    localparam integer I2C_HALF_PERIOD = 60;
    localparam integer POWERUP_CYCLES = 1200000; // ~100 ms at 12 MHz

    localparam [3:0] ST_POWERUP     = 4'd0;
    localparam [3:0] ST_PREPARE_MSG = 4'd1;
    localparam [3:0] ST_START_A     = 4'd2;
    localparam [3:0] ST_START_B     = 4'd3;
    localparam [3:0] ST_SEND_LOW    = 4'd4;
    localparam [3:0] ST_SEND_HIGH   = 4'd5;
    localparam [3:0] ST_ACK_LOW     = 4'd6;
    localparam [3:0] ST_ACK_HIGH    = 4'd7;
    localparam [3:0] ST_STOP_A      = 4'd8;
    localparam [3:0] ST_STOP_B      = 4'd9;
    localparam [3:0] ST_NEXT_MSG    = 4'd10;
    localparam [3:0] ST_DONE        = 4'd11;

    reg [3:0] state = ST_POWERUP;
    reg [23:0] powerup_count = 24'd0;
    reg [7:0] div_count = 8'd0;

    reg scl_r = 1'b1;
    reg sda_drive_low = 1'b0;
    wire sda_in;

    reg [1:0] msg_idx = 2'd0;
    reg [4:0] byte_total = 5'd0;
    reg [4:0] byte_idx = 5'd0;
    reg [3:0] bit_idx = 4'd0;
    reg [7:0] shifter = 8'd0;
    reg nack_seen = 1'b0;

    wire tick = (div_count == I2C_HALF_PERIOD - 1);

    assign scl = scl_r;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign sda_in = sda;

    function [4:0] payload_len;
        input [1:0] msg;
        begin
            case (msg)
                2'd0: payload_len = 5'd1;  // 0x21: oscillator on
                2'd1: payload_len = 5'd1;  // 0x81: display on, no blink
                2'd2: payload_len = 5'd1;  // 0xE6: brightness level 6
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
                2'd2: payload_byte = 8'hE6;
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

    function [7:0] tx_byte;
        input [1:0] msg;
        input [4:0] idx;
        begin
            if (idx == 5'd0) begin
                tx_byte = 8'hE0; // 7-bit address 0x70 with write bit
            end else begin
                tx_byte = payload_byte(msg, idx - 5'd1);
            end
        end
    endfunction

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_POWERUP;
            powerup_count <= 24'd0;
            div_count <= 8'd0;
            scl_r <= 1'b1;
            sda_drive_low <= 1'b0;
            msg_idx <= 2'd0;
            byte_total <= 5'd0;
            byte_idx <= 5'd0;
            bit_idx <= 4'd0;
            shifter <= 8'd0;
            nack_seen <= 1'b0;
        end else begin
            if (div_count == I2C_HALF_PERIOD - 1) begin
                div_count <= 8'd0;
            end else begin
                div_count <= div_count + 8'd1;
            end

            if (state == ST_POWERUP) begin
                scl_r <= 1'b1;
                sda_drive_low <= 1'b0;
                if (powerup_count < POWERUP_CYCLES) begin
                    powerup_count <= powerup_count + 24'd1;
                end else begin
                    state <= ST_PREPARE_MSG;
                end
            end else if (tick) begin
                case (state)
                    ST_PREPARE_MSG: begin
                        byte_total <= payload_len(msg_idx) + 5'd1;
                        byte_idx <= 5'd0;
                        bit_idx <= 4'd7;
                        shifter <= tx_byte(msg_idx, 5'd0);
                        scl_r <= 1'b1;
                        sda_drive_low <= 1'b0;
                        state <= ST_START_A;
                    end

                    ST_START_A: begin
                        scl_r <= 1'b1;
                        sda_drive_low <= 1'b1;
                        state <= ST_START_B;
                    end

                    ST_START_B: begin
                        scl_r <= 1'b0;
                        bit_idx <= 4'd7;
                        state <= ST_SEND_LOW;
                    end

                    ST_SEND_LOW: begin
                        scl_r <= 1'b0;
                        sda_drive_low <= ~shifter[bit_idx];
                        state <= ST_SEND_HIGH;
                    end

                    ST_SEND_HIGH: begin
                        scl_r <= 1'b1;
                        if (bit_idx == 4'd0) begin
                            state <= ST_ACK_LOW;
                        end else begin
                            bit_idx <= bit_idx - 4'd1;
                            state <= ST_SEND_LOW;
                        end
                    end

                    ST_ACK_LOW: begin
                        scl_r <= 1'b0;
                        sda_drive_low <= 1'b0;
                        state <= ST_ACK_HIGH;
                    end

                    ST_ACK_HIGH: begin
                        scl_r <= 1'b1;
                        if (sda_in) begin
                            nack_seen <= 1'b1;
                        end

                        if (byte_idx + 5'd1 < byte_total) begin
                            byte_idx <= byte_idx + 5'd1;
                            bit_idx <= 4'd7;
                            shifter <= tx_byte(msg_idx, byte_idx + 5'd1);
                            state <= ST_SEND_LOW;
                        end else begin
                            state <= ST_STOP_A;
                        end
                    end

                    ST_STOP_A: begin
                        scl_r <= 1'b0;
                        sda_drive_low <= 1'b1;
                        state <= ST_STOP_B;
                    end

                    ST_STOP_B: begin
                        scl_r <= 1'b1;
                        sda_drive_low <= 1'b0;
                        state <= ST_NEXT_MSG;
                    end

                    ST_NEXT_MSG: begin
                        if (msg_idx == 2'd3) begin
                            state <= ST_DONE;
                        end else begin
                            msg_idx <= msg_idx + 2'd1;
                            state <= ST_PREPARE_MSG;
                        end
                    end

                    ST_DONE: begin
                        scl_r <= 1'b1;
                        sda_drive_low <= 1'b0;
                    end

                    default: begin
                        state <= ST_POWERUP;
                    end
                endcase
            end
        end
    end
endmodule
