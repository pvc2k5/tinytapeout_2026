module pwm_core #(
    parameter DATA_WIDTH = 8,
    parameter N_CH       = 4
)(
    input                           clk,
    input                           rst_n,
    input                           pwm_clk_en,
    input  [N_CH*DATA_WIDTH-1:0]    dc,
    input  [N_CH*DATA_WIDTH-1:0]    phase,
    output [N_CH-1:0]               raw
);
    reg [DATA_WIDTH-1:0] cnt;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= {DATA_WIDTH{1'b0}};
        else if (pwm_clk_en)
            cnt <= cnt + 1'b1;
    end

    genvar g;
    generate
        for (g = 0; g < N_CH; g = g+1) begin : gen_compare
            assign raw[g] = (phase[g*DATA_WIDTH +: DATA_WIDTH] + cnt)
                             < dc[g*DATA_WIDTH +: DATA_WIDTH];
        end
    endgenerate

endmodule
