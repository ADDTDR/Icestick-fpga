# hcms_display

Standalone   reusable Verilog module for HCMS-29xx 4-digit integer display.

## What this gives you

- Reusable module: `hcms29xx_integer_display`
- Input is a binary integer value (`0` to `9999`)
- Display format is always zero-padded: `0000` .. `9999`
- Easy to drop into another project

## Files

- `hcms29xx_integer_display.v`: integer to 4-digit HCMS rendering + HCMS control words
- `hcms_serial_byte.v`: low-level byte serializer for HCMS pins
- `top.v`: demo top-level that counts from `0000` to `9999`

## Pin mapping

Uses the same PMOD mapping as your existing `hcms_29xx` project, but with explicit top-level HCMS signal names:

- `HCMS_DATA_O` -> PMOD_1
- `HCMS_CLOCK_O` -> PMOD_2
- `HCMS_REGSEL_O` -> PMOD_3
- `HCMS_NCS_O` -> PMOD_4
- `HCMS_RESET_O` -> PMOD_5

## Build / upload

```bash
cd hcms_display
apio build
apio upload
```

## Reuse in another project

Instantiate this module and drive `i_value`:

```verilog
hcms29xx_integer_display u_display (
    .i_clk(CLK_I),
    .i_value(my_value_0_to_9999),
    .i_pwm(4'b0111),
    .i_current(2'b00),
    .i_sleep(1'b1),
    .o_hcms_data(HCMS_DATA_O),
    .o_hcms_clock(HCMS_CLOCK_O),
    .o_hcms_regsel(HCMS_REGSEL_O),
    .o_hcms_ncs(HCMS_NCS_O),
    .o_hcms_reset(HCMS_RESET_O)
);
```
