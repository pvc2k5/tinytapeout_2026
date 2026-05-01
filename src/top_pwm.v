module top #(
    parameter N_CH       = 7,
    parameter DATA_WIDTH = 8
)(
    input  clk,
    input  rst_n,
    input  sck,
    input  mosi,
    input  cs_n,
    output miso,
    input  n_fault,
    output [N_CH-1:0] out_h,
    output [N_CH-1:0] out_l
);

    wire [4:0]              reg_addr;
    wire [7:0]              reg_wdata;
    wire                    reg_we;
    wire [7:0]              reg_rdata;

    wire [9:0]              pre_div;
    wire [N_CH*DATA_WIDTH-1:0] dc;
    wire [N_CH*DATA_WIDTH-1:0] phase;
    wire [7:0]              enable;
    wire [7:0]              deadtime;
    wire                    fault_clr;
    wire                    fault_latch;
    wire                    shutdown;

    wire                    pwm_clk_en;
    wire [N_CH-1:0]         raw;
    wire [N_CH-1:0]         pwm_h;
    wire [N_CH-1:0]         pwm_l;

    //SPI Interface
    spi_pwm spi (
        .clk       (clk),
        .rst_n     (rst_n),
        .sck       (sck),
        .mosi      (mosi),
        .cs_n      (cs_n),
        .miso      (miso),
        .reg_rdata (reg_rdata),
        .reg_addr  (reg_addr),
        .reg_wdata (reg_wdata),
        .reg_we    (reg_we)
    );

    //Register File
    register_file #(
        .N_CH       (N_CH),
        .DATA_WIDTH (DATA_WIDTH)
    ) regfile (
        .clk       (clk),
        .rst_n     (rst_n),
        .reg_addr  (reg_addr),
        .reg_wdata (reg_wdata),
        .reg_we    (reg_we),
        .fault_in  (fault_latch),
        .reg_rdata (reg_rdata),
        .pre_div   (pre_div),
        .dc        (dc),
        .phase     (phase),
        .enable    (enable),
        .deadtime  (deadtime),
        .fault_clr (fault_clr)
    );

    //Prescaler
    prescaler pre (
        .clk       (clk),
        .rst_n     (rst_n),
        .div       (pre_div),
        .pwm_clk_en(pwm_clk_en)
    );

    //PWM Core
    pwm_core #(
        .DATA_WIDTH (DATA_WIDTH),
        .N_CH       (N_CH)
    ) core (
        .clk       (clk),
        .rst_n     (rst_n),
        .pwm_clk_en(pwm_clk_en),
        .dc        (dc),
        .phase     (phase),
        .raw       (raw)
    );

    //Dead-time × 8
    genvar i;
    generate
        for (i = 0; i < N_CH; i = i+1) begin : gen_dt
            dead_time #(
                .DATA_WIDTH (DATA_WIDTH)
            ) dt (
                .clk      (clk),
                .rst_n    (rst_n),
                .pwm_in   (raw[i]),
                .dt_cycles(deadtime),
                .pwm_h    (pwm_h[i]),
                .pwm_l    (pwm_l[i])
            );
        end
    endgenerate

    //Fault Protection
    fault_protection fault (
        .clk        (clk),
        .rst_n      (rst_n),
        .n_fault    (n_fault),
        .fault_clr  (fault_clr),
        .fault_latch(fault_latch),
        .shutdown   (shutdown)
    );

    //Output Mux
    mux_out #(
        .N_CH (N_CH)
    ) mux (
        .pwm_h   (pwm_h),
        .pwm_l   (pwm_l),
        .enable  (enable),
        .shutdown(shutdown),
        .out_h   (out_h),
        .out_l   (out_l)
    );

endmodule