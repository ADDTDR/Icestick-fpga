module top(
    input wire CLK_i,
	output wire SCL_PIN,
	inout wire SDA_PIN
   
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

ht16k33 ht16k33_inst (
    .clk(CLK_i),
    .rst(rst),
    .payload_addr(payload_addr),
    .payload_data(payload_data),
    .i2c_start(i2c_start),
    .i2c_address(i2c_address),
    .i2c_byte_count(i2c_byte_count),
    .i2c_tx_byte(i2c_tx_byte),
    .i2c_byte_index(i2c_byte_index),
    .i2c_busy(i2c_busy),
    .i2c_done(i2c_done),
    .i2c_ack_error(i2c_ack_error),
    .nack_seen(nack_seen)
);

payload_mem payload_mem_inst (
    .addr(payload_addr),
    .data(payload_data)
);

i2c_master i2c_master_inst (
    .clk(CLK_i),
    .rst(rst),
    .start(i2c_start),
    .address(i2c_address),
    .byte_count(i2c_byte_count),
    .tx_byte(i2c_tx_byte),
    .scl(SCL_PIN),
    .sda(SDA_PIN),
    .byte_index(i2c_byte_index),
    .busy(i2c_busy),
    .done(i2c_done),
    .ack_error(i2c_ack_error)
);
endmodule