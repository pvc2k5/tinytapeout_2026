`default_nettype none
 
// ============================================================================
// Tiny Tapeout wrapper — 7-channel PWM controller
// ============================================================================
// Pin map:
//   ui_in[0]     → sck       SPI clock
//   ui_in[1]     → mosi      SPI data in
//   ui_in[2]     → cs_n      SPI chip select (active low)
//   ui_in[3]     → n_fault   Fault input from driver IC (active low)
//   ui_in[7:4]   → unused
//
//   uo_out[6:0]  → out_h[6:0]  High-side PWM, 7 channels
//   uo_out[7]    → 0           unused
//
//   uio_out[6:0] → out_l[6:0]  Low-side PWM, 7 channels
//   uio_out[7]   → miso        SPI data out
//   uio_oe[7:0]  → 8'hFF       all uio are outputs
// ============================================================================
 
module tt_um_pwm7ch (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire       ena,
    input  wire       clk,
    input  wire       rst_n
);
    wire [6:0] out_h;
    wire [6:0] out_l;
    wire       miso;
 
    top #(
        .N_CH      (7),
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
 
    assign uo_out  = {1'b0, out_h};   // bit7 unused
    assign uio_out = {miso, out_l};   // bit7=miso, bit6:0=out_l
    assign uio_oe  = 8'hFF;           // tất cả uio là output
 
    wire _unused = &{ena, uio_in};
 
endmodule
 