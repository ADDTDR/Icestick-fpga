module payload_mem (
    input wire [3:0] addr,
    output reg [7:0] data
);
    // Segment payload bytes for digits 1..9, remaining slots are blank.
    always @(*) begin
        case (addr)
            4'd0: data = 8'h06; // 1
            4'd1: data = 8'h5B; // 2
            4'd2: data = 8'h4F; // 3
            4'd3: data = 8'h66; // 4
            4'd4: data = 8'h6D; // 5
            4'd5: data = 8'h7D; // 6
            4'd6: data = 8'h07; // 7
            4'd7: data = 8'h7F; // 8
            4'd8: data = 8'h6F; // 9
            default: data = 8'h00;
        endcase
    end
endmodule
