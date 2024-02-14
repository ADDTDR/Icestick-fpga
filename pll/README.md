# PLL usage example 

- ### check latice system guide design pll documentation 

- ### Run ice pll tool for 120MHz output clock using as reference 12MHz
```
 $ apio raw "icepll -i 12 -o 120"
```
- ### Output 
```
F_PLLIN:    12.000 MHz (given)
F_PLLOUT:  120.000 MHz (requested)
F_PLLOUT:  120.000 MHz (achieved)

FEEDBACK: SIMPLE
F_PFD:   12.000 MHz
F_VCO:  960.000 MHz

DIVR:  0 (4'b0000)
DIVF: 79 (7'b1001111)
DIVQ:  3 (3'b011)

FILTER_RANGE: 1 (3'b001)
```

- ### Init pll in verilog  
```verilog

module pll_module (
    input clk_i,
    output clk_o
); 
    SB_PLL40_CORE #(
        .FEEDBACK_PATH("SIMPLE"), // Don't use fine delay adjustment 
        .PLLOUT_SELECT("GENCLK"), // No phase shift on output 
        .DIVR(4'b0000),           // Reference clock divider 
        .DIVF(7'b1001111),        // Feedback divider 
        .DIVQ(3'b011),            // VCO clock divider  
        .FILTER_RANGE(3'b001)     // Filter range   
    ) pll (
        .REFERENCECLK(clk_i),     // Clock input 
        .PLLOUTCORE(clk_o),       // Clock output 
        .LOCK(),                  // Locked signal 
        .RESETB(1'b1),            // Active low reset   
        .BYPASS(1'b0)             // No bypass, use PLL signal as outputl 
    ); 
endmodule
```

- ### Build and flash the icestick fpga board 
```bash
$ apio verify 
$ apio build -v 
$ apio upload
```