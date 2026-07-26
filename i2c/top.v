module top(
    input wire CLK_i,
	output wire SCL_PIN,
	inout wire SDA_PIN, 

    // LEDS
    output wire D5,
    output wire D4,
    output wire D3,
    output wire D2
   
    );

wire rst = 1'b0;
wire [3:0] payload_addr;
wire [7:0] payload_data;

wire i2c_start;
wire [6:0] i2c_address;
wire [4:0] i2c_byte_count;
wire [7:0] i2c_tx_byte;
wire [4:0] i2c_byte_index;
wire i2c_busy;
wire i2c_done;
wire i2c_ack_error;
wire nack_seen;
wire i2c_read;
wire [7:0] i2c_rx_byte;
wire i2c_rx_valid;
wire key_a;
wire key_b;
wire key_c;
wire key_d;

assign D5 = key_a;
assign D4 = key_b;
assign D3 = key_c;
assign D2 = key_d;

ht16k33 ht16k33_inst (
    .clk(CLK_i),
    .rst(rst),
    .payload_addr(payload_addr),
    .payload_data(payload_data),
    .i2c_start(i2c_start),
    .i2c_read(i2c_read),
    .i2c_address(i2c_address),
    .i2c_byte_count(i2c_byte_count),
    .i2c_tx_byte(i2c_tx_byte),
    .i2c_byte_index(i2c_byte_index),
    .i2c_busy(i2c_busy),
    .i2c_done(i2c_done),
    .i2c_ack_error(i2c_ack_error),
    .i2c_rx_byte(i2c_rx_byte),
    .i2c_rx_valid(i2c_rx_valid),
    .nack_seen(nack_seen),
    .key_a(key_a),
    .key_b(key_b),
    .key_c(key_c),
    .key_d(key_d)
);

payload_mem payload_mem_inst (
    .addr(payload_addr),
    .data(payload_data)
);

i2c_master i2c_master_inst (
    .clk(CLK_i),
    .rst(rst),
    .start(i2c_start),
    .read(i2c_read),
    .address(i2c_address),
    .byte_count(i2c_byte_count),
    .tx_byte(i2c_tx_byte),
    .scl(SCL_PIN),
    .sda(SDA_PIN),
    .byte_index(i2c_byte_index),
    .busy(i2c_busy),
    .done(i2c_done),
    .ack_error(i2c_ack_error),
    .rx_byte(i2c_rx_byte),
    .rx_valid(i2c_rx_valid)
);
endmodule