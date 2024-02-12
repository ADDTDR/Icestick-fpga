module top_checkered (
    input  wire clk,
    output wire oled_cs,
    output wire oled_clk,
    output wire oled_mosi,
    output wire oled_dc,
    output wire reset,
    output D5,
    output D4
);
    //                  checkered      red   green      blue     red       green blue
    wire [15:0] pattern1 = x[i] ^ y[3] ? {5'd0, 6'b111111, 5'd0} : {5'd60, 6'd0, 5'b11111};
    // wire [15:0] pattern2 = (x>8'd80) ? {5'd0, 6'b111111, 5'd0} : {5'b11111, 6'd0, 5'd0};

    // wire [15:0] color = (switch<24'h5B8D80) ? pattern1 : pattern2;
    wire [15:0] color = pattern1;

    reg [23:0] switch;
    reg [7:0] i;
    // reg [20:0] clock = 0; 
    // reg cc; 
    reg x_ready_led;
    reg y_ready_led;

    assign D5 = x_ready_led;
    assign D4 = y_ready_led;


    initial begin
        switch = 0;
        i = 0; 
    end


//     always@(posedge clk)begin 
//       clock <= clock + 1;
//       cc <= clock[19];
//    end 
 
    
    always@(posedge clk)begin
        if (x > 158) begin
            x_ready_led <= 1;
            i <= i + 1;
        end
        else 
            x_ready_led <= 0;

        if (y > 78) 
            y_ready_led <= 1;
        else 
            y_ready_led <= 0;

        if (i > 9)
            i <= 0;
          

    end

    // always@(negedge cc)
    //     begin
    //       if (i == 9)
    //         i <= 0;
    //       else   
    //         i <= i + 1;
    //      end  

    wire [7:0] x;
    wire [6:0] y;


    st7735  driver (
        .clk(clk),
        .x(x),
        .y(y),
        .color(color),
        // .next_pixel(next_pixel),
        .oled_cs(oled_cs),
        .oled_clk(oled_clk),
        .oled_mosi(oled_mosi),
        .oled_dc(oled_dc),
        .reset(reset)
    );

endmodule
