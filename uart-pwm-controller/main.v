module main(
    input CLK_i,
    output D1,
	output D2,
	output D3,
	output D4,
	output D5,
	output D6,
	output D7, 
	output D8,
	output TX_TO_FTDI,
	input RX_FROM_FTDI
   
    );
	// assign D1 = tx_busy;
    // assign D1 = 0;
	// assign D2 = 0;
	// assign D3 = 0;
	// assign D4 = 0;
	// assign D5 = 1;
	// assign D6 = 1;
	// assign D7 = 1;
	// assign D8 = 1;
	// assign D5 = RxD_data_ready;
	// a = 0x61
    // reg [7:0] txd = 8'h61;
    // reg tx_start = 1'b1;
	wire tx_busy;
	wire RxD_data_ready;
	wire [7:0] RxD_data;
	reg [7:0] GPout;

	reg [3:0] mem_address = 4'h0;

	reg [7:0]  mem [0:8];


	

	

	// Receive data 
	uart_receiver RX(.clk(CLK_i), .RxD(RX_FROM_FTDI), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
	always @(posedge RxD_data_ready) begin
		GPout <= RxD_data;
		

		if (RxD_data == 0)
            mem_address <= 4'h0;
        else   
            mem_address <= mem_address + 1;
			if (RxD_data != 0)
				mem[mem_address] <=  RxD_data;
	end
	 

    PWM pwm_1(
        .clk(CLK_i),
        .PWM_in(mem[0]),
        .PWM_out(D1)
    );

	PWM pwm_2(
        .clk(CLK_i),
        .PWM_in(mem[1]),
        .PWM_out(D2)
    );

	PWM pwm_3(
        .clk(CLK_i),
        .PWM_in(mem[2]),
        .PWM_out(D3)
    );

	PWM pwm_4(
        .clk(CLK_i),
        .PWM_in(mem[3]),
        .PWM_out(D4)
    );

	PWM pwm_5(
        .clk(CLK_i),
        .PWM_in(mem[4]),
        .PWM_out(D5)
    );

	PWM pwm_6(
        .clk(CLK_i),
        .PWM_in(mem[5]),
        .PWM_out(D6)
    );

	PWM pwm_7(
        .clk(CLK_i),
        .PWM_in(mem[6]),
        .PWM_out(D7)
    );

	PWM pwm_8(
        .clk(CLK_i),
        .PWM_in(mem[7]),
        .PWM_out(D8)
    );

	// Transmit received data + 1 
	uart_transmitter TX(.clk(CLK_i), .TxD(TX_TO_FTDI), .TxD_start(RxD_data_ready), .TxD_data(GPout + 2), .TxD_busy(tx_busy));



endmodule