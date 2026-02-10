module top(input i_clk);

reg [7:0] memory_address = 'd0; 
reg [7:0] data;

always @(posedge i_clk)begin
    
    if(memory_address < 15)
        memory_address <= memory_address + 1;
    else
        memory_address <= 0;    
end 

memory storage(
    .clk(i_clk),
    .r_addr(memory_address),
    .r_en(1'b1),
    .r_data(data)

);

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