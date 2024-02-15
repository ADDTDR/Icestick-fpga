module top (
    input clk, 
    output D1,
    output D2,
	output D3,
	output D4,
	output D5,
    output TX_TO_FTDI,
	input RX_FROM_FTDI
);

    
    wire [7:0] data;
    wire tx_busy;
    reg RxD_data_ready;
	wire [7:0] RxD_data;
	reg [7:0] GPout;
    reg [7:0] r_addr;

    initial 
        r_addr <= 0;

    assign D1 = tx_busy;
	assign D2 = 0;
	assign D3 = 0;
	assign D5 = RxD_data_ready;

    memory mem_strorage(
        .clk(clk),
        .w_en(1'b0),
        .r_en(1'b1),
        .w_addr(8'h00),
        .w_data(8'h61),
        .r_addr(r_addr),
        .r_data(data)
    );

    always @(negedge tx_busy ) begin
        RxD_data_ready <=0;

        if (r_addr == 15) 
            r_addr <= 0 ;
        else
            r_addr <= r_addr + 1;

        RxD_data_ready <=1;

       
    end
    // uart_receiver RX(.clk(CLK_i), .RxD(RX_FROM_FTDI), .RxD_data_ready(RxD_data_ready), .RxD_data(RxD_data));
	// always @(posedge RxD_data_ready)  GPout <= RxD_data;

	uart_transmitter TX(.clk(clk), .TxD(TX_TO_FTDI), .TxD_start(RxD_data_ready), .TxD_data(data), .TxD_busy(tx_busy));

    assign D4 = data[0];
endmodule

// Infered block RAM 
module memory #(
    parameter INIT_FILE = "mem_init.txt"
)(
    input clk,
    input w_en,
    input r_en,
    input [7:0] w_addr,
    input [7:0] r_addr,
    input [7:0] w_data, 

    output reg [7:0] r_data
);

    reg [7:0]  mem [0:255];

    always @(posedge clk) begin
        if (w_en == 1'b1) begin
            mem[w_addr] <= w_data;    
        end
        
        if (r_en == 1'b1) begin
            r_data <= mem[r_addr];
        end
    end

    initial if (INIT_FILE) begin
        $readmemh(INIT_FILE, mem);
    end
    
endmodule