module top(
    input CLK_i,
    output D1,
    output D2,
    output D3,
    output D4,
    output D5
    );

reg [7:0] memory_address = 'd0; 
reg [7:0] data;
reg clk;

assign D1 = data[0];
assign D2 = data[1];
assign D3 = data[2];
assign D4 = data[3];
assign D5 = data[4];

clkDivider cldiv(
    .clk_i(CLK_i),
    .clk_o(clk)
);

always @(posedge clk)begin
    
    if(memory_address < 15)
        memory_address <= memory_address + 1;
    else
        memory_address <= 0;    
end 

memory storage(
    .clk(clk),
    .r_addr(memory_address),
    .r_en(1'b1),
    .r_data(data),
    .w_en(1'b0)

);

endmodule


module clkDivider(
    input clk_i,
    output clk_o
);

reg [20:0] counter = 0; 
assign clk_o = counter[20];

always @(posedge clk_i)begin
    counter <= counter + 1;
    end


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