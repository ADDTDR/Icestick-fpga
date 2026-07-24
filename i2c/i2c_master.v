module i2c_master (
    input wire clk,
    input wire rst,
    input wire start,
    input wire [6:0] address,
    input wire [4:0] byte_count,
    input wire [7:0] tx_byte,
    output wire scl,
    inout wire sda,
    output reg [4:0] byte_index,
    output reg busy,
    output reg done,
    output reg ack_error
);

    localparam integer I2C_HALF_PERIOD = 60;

    localparam [3:0] ST_IDLE      = 4'd0;
    localparam [3:0] ST_START_A   = 4'd1;
    localparam [3:0] ST_START_B   = 4'd2;
    localparam [3:0] ST_LOAD_BYTE = 4'd3;
    localparam [3:0] ST_SEND_LOW  = 4'd4;
    localparam [3:0] ST_SEND_HIGH = 4'd5;
    localparam [3:0] ST_ACK_LOW   = 4'd6;
    localparam [3:0] ST_ACK_HIGH  = 4'd7;
    localparam [3:0] ST_STOP_A    = 4'd8;
    localparam [3:0] ST_STOP_B    = 4'd9;
    localparam [3:0] ST_FINISH    = 4'd10;

    reg [3:0] state = ST_IDLE;
    reg [7:0] div_count = 8'd0;
    reg [3:0] bit_idx = 4'd0;
    reg [7:0] shifter = 8'd0;
    reg [4:0] count_latched = 5'd0;
    reg sending_address = 1'b0;

    reg scl_r = 1'b1;
    reg sda_drive_low = 1'b0;

    wire tick = (div_count == I2C_HALF_PERIOD - 1);
    wire sda_in;

    assign scl = scl_r;
    assign sda = sda_drive_low ? 1'b0 : 1'bz;
    assign sda_in = sda;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= ST_IDLE;
            div_count <= 8'd0;
            bit_idx <= 4'd0;
            shifter <= 8'd0;
            count_latched <= 5'd0;
            sending_address <= 1'b0;
            scl_r <= 1'b1;
            sda_drive_low <= 1'b0;
            byte_index <= 5'd0;
            busy <= 1'b0;
            done <= 1'b0;
            ack_error <= 1'b0;
        end else begin
            done <= 1'b0;

            if (div_count == I2C_HALF_PERIOD - 1) begin
                div_count <= 8'd0;
            end else begin
                div_count <= div_count + 8'd1;
            end

            if (state == ST_IDLE) begin
                scl_r <= 1'b1;
                sda_drive_low <= 1'b0;
                busy <= 1'b0;

                if (start) begin
                    busy <= 1'b1;
                    ack_error <= 1'b0;
                    count_latched <= byte_count;
                    byte_index <= 5'd0;
                    sending_address <= 1'b1;
                    state <= ST_START_A;
                end
            end else if (tick) begin
                case (state)
                    ST_START_A: begin
                        scl_r <= 1'b1;
                        sda_drive_low <= 1'b1;
                        state <= ST_START_B;
                    end

                    ST_START_B: begin
                        scl_r <= 1'b0;
                        bit_idx <= 4'd7;
                        state <= ST_LOAD_BYTE;
                    end

                    ST_LOAD_BYTE: begin
                        if (sending_address) begin
                            shifter <= {address, 1'b0};
                        end else begin
                            shifter <= tx_byte;
                        end
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
                            ack_error <= 1'b1;
                        end

                        if (sending_address) begin
                            sending_address <= 1'b0;
                            if (count_latched == 5'd0) begin
                                state <= ST_STOP_A;
                            end else begin
                                state <= ST_LOAD_BYTE;
                            end
                        end else if (byte_index + 5'd1 < count_latched) begin
                            byte_index <= byte_index + 5'd1;
                            state <= ST_LOAD_BYTE;
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
                        state <= ST_FINISH;
                    end

                    ST_FINISH: begin
                        busy <= 1'b0;
                        done <= 1'b1;
                        state <= ST_IDLE;
                    end

                    default: begin
                        state <= ST_IDLE;
                    end
                endcase
            end
        end
    end
endmodule
