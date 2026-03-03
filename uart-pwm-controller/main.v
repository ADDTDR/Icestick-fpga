module main(
    input CLK_i,
    output D1,
	output D2,
	output D3,
	output D4,
	output D5,
	output TX_TO_FTDI,
	input RX_FROM_FTDI
   
    );
	// assign D1 = tx_busy;
    assign D1 = 0;
	assign D2 = 0;
	assign D3 = 0;
	assign D4 = 0;
	// assign D5 = RxD_data_ready;
	// a = 0x61
    // reg [7:0] txd = 8'h61;
    // reg tx_start = 1'b1;
	wire tx_busy;
	wire RxD_data_ready;
	wire [7:0] RxD_data;
	reg [7:0] GPout;

	// reg [7:0] i = 8'h61;
	

    // always@(negedge tx_busy)begin
    //       txd <= i;
		  
    //       if (i == 8'h61 + 32)
    //         i <= 8'h61;
    //       else   
    //         i <= i + 1;
    // 	end  


  

	

	// Receive data 
	uart_receiver RX(.clk(CLK_i), .RxD(RX_FROM_FTDI), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
	always @(posedge RxD_data_ready)  GPout <= RxD_data;

    PWM pwm(
        .clk(CLK_i),
        .PWM_in(GPout),
        .PWM_out(D5)
    );
	// Transmit received data + 1 
	uart_transmitter TX(.clk(CLK_i), .TxD(TX_TO_FTDI), .TxD_start(RxD_data_ready), .TxD_data(GPout + 2), .TxD_busy(tx_busy));



endmodule