module top (
    input clk, 
    output D1
);
    wire [7:0] data;

    memory mem_strorage(
        .clk(clk),
        .w_en(1'b1),
        .r_en(1'b1),
        .w_addr(8'h00),
        .w_data(8'h61),
        .r_addr(8'h00),
        .r_data(data)
    );

    assign D1 = data[0];
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