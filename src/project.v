`default_nettype none

// ============================================================================
// Tiny Tapeout wrapper — 4-channel PWM controller
// ============================================================================
// Pin map:
//   ui_in[0]     → sck       SPI clock
//   ui_in[1]     → mosi      SPI data in
//   ui_in[2]     → cs_n      SPI chip select (active low)
//   ui_in[3]     → n_fault   Fault input (active low)
//   ui_in[7:4]   → unused
//
//   uo_out[3:0]  → out_h[3:0]  High-side PWM, 4 channels
//   uo_out[7:4]  → out_l[3:0]  Low-side PWM, 4 channels
//
//   uio_out[7]   → miso        SPI data out
//   uio_out[6:0] → unused
//   uio_oe[7]    → 1           miso is output
//   uio_oe[6:0]  → 0           unused pins are input
// ============================================================================

module tt_um_pwm_4ch (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire [3:0] out_h;
    wire [3:0] out_l;
    wire       miso;

    top #(
        .N_CH      (4),
        .DATA_WIDTH(8)
    ) pwm_top (
        .clk     (clk),
        .rst_n   (rst_n),
        .sck     (ui_in[0]),
        .mosi    (ui_in[1]),
        .cs_n    (ui_in[2]),
        .n_fault (ui_in[3]),
        .miso    (miso),
        .out_h   (out_h),
        .out_l   (out_l)
    );

    assign uo_out  = {out_l, out_h};     // [7:4]=out_l, [3:0]=out_h
    assign uio_out = {miso, 7'b0};       // bit7=miso
    assign uio_oe  = 8'h80;              // chỉ bit7 là output

    wire _unused = &{ena, uio_in, ui_in[7:4]};

endmodule
