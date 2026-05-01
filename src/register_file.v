// ============================================================================
// Register Map — PWM 4-Channel Controller
// ============================================================================
//  Addr   Name        R/W   Width   Description
// ------  ----------  ---   -----   -----------------------------------------
//  0x00   PRE_L       R/W     8     Prescaler low byte
//  0x01   PRE_H       R/W     8     Prescaler high bits (use only [1:0])
//  0x02   DUTY_CH0    R/W     8     Duty cycle channel 0
//  0x03   DUTY_CH1    R/W     8     Duty cycle channel 1
//  0x04   DUTY_CH2    R/W     8     Duty cycle channel 2
//  0x05   DUTY_CH3    R/W     8     Duty cycle channel 3
//  0x06   PHASE_CH0   R/W     8     Phase offset channel 0
//  0x07   PHASE_CH1   R/W     8     Phase offset channel 1
//  0x08   PHASE_CH2   R/W     8     Phase offset channel 2
//  0x09   PHASE_CH3   R/W     8     Phase offset channel 3
//  0x0A   ENABLE      R/W     8     Output enable mask [3:0] (1 = enabled)
//  0x0B   DEADTIME    R/W     8     Dead-time cycles (0 = disabled)
//  0x0C   FAULT_CLR   W       8     Write 1 to clear fault latch (auto-clears)
//  0x0D   STATUS      R       8     Fault status - bit0 = fault_latch
//  0x0E   DEVICE_ID   R       8     Device identifier - fixed 0x50
// ============================================================================

module register_file #(
    parameter N_CH       = 4,
    parameter DATA_WIDTH = 8
)(
    input             clk,
    input             rst_n,
    input      [4:0]  reg_addr,
    input      [7:0]  reg_wdata,
    input             reg_we,
    input             fault_in,
    output reg [7:0]  reg_rdata,
    output     [9:0]  pre_div,
    output     [N_CH*DATA_WIDTH-1:0] dc,
    output     [N_CH*DATA_WIDTH-1:0] phase,
    output     [N_CH-1:0] enable,
    output     [7:0]  deadtime,
    output            fault_clr
);

    reg [7:0] PRE_L;
    reg [7:0] PRE_H;
    reg [7:0] DUTY  [0:N_CH-1];
    reg [7:0] PHASE [0:N_CH-1];
    reg [7:0] ENABLE;
    reg [7:0] DEADTIME;
    reg [7:0] FAULT_CLR;
    reg [7:0] STATUS;

    integer j;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PRE_L     <= 8'h00;
            PRE_H     <= 8'h00;
            for (j = 0; j < N_CH; j = j+1) begin
                DUTY[j]  <= 8'h00;
                PHASE[j] <= 8'h00;
            end
            ENABLE    <= 8'hFF;
            DEADTIME  <= 8'h00;
            FAULT_CLR <= 8'h00;
            STATUS    <= 8'h00;
        end else begin
            FAULT_CLR <= 8'h00;
            STATUS    <= {7'b0, fault_in};
            if (reg_we) begin
                case (reg_addr)
                    5'h00: PRE_L     <= reg_wdata;
                    5'h01: PRE_H     <= reg_wdata;
                    5'h02: DUTY[0]   <= reg_wdata;
                    5'h03: DUTY[1]   <= reg_wdata;
                    5'h04: DUTY[2]   <= reg_wdata;
                    5'h05: DUTY[3]   <= reg_wdata;
                    5'h06: PHASE[0]  <= reg_wdata;
                    5'h07: PHASE[1]  <= reg_wdata;
                    5'h08: PHASE[2]  <= reg_wdata;
                    5'h09: PHASE[3]  <= reg_wdata;
                    5'h0A: ENABLE    <= reg_wdata;
                    5'h0B: DEADTIME  <= reg_wdata;
                    5'h0C: FAULT_CLR <= reg_wdata;
                    default: ;
                endcase
            end
        end
    end

    always @* begin
        case (reg_addr)
            5'h00: reg_rdata = PRE_L;
            5'h01: reg_rdata = PRE_H;
            5'h02: reg_rdata = DUTY[0];
            5'h03: reg_rdata = DUTY[1];
            5'h04: reg_rdata = DUTY[2];
            5'h05: reg_rdata = DUTY[3];
            5'h06: reg_rdata = PHASE[0];
            5'h07: reg_rdata = PHASE[1];
            5'h08: reg_rdata = PHASE[2];
            5'h09: reg_rdata = PHASE[3];
            5'h0A: reg_rdata = ENABLE;
            5'h0B: reg_rdata = DEADTIME;
            5'h0C: reg_rdata = FAULT_CLR;
            5'h0D: reg_rdata = STATUS;
            5'h0E: reg_rdata = 8'h50;
            default: reg_rdata = 8'h00;
        endcase
    end

    assign pre_div   = {PRE_H[1:0], PRE_L};
    assign enable    = ENABLE[N_CH-1:0];
    assign deadtime  = DEADTIME;
    assign fault_clr = FAULT_CLR[0];

    genvar i;
    generate
        for (i = 0; i < N_CH; i = i+1) begin : gen_out
            assign dc   [i*DATA_WIDTH +: DATA_WIDTH] = DUTY[i];
            assign phase[i*DATA_WIDTH +: DATA_WIDTH] = PHASE[i];
        end
    endgenerate

endmodule
