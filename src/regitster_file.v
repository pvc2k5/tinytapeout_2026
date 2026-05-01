// ============================================================================
// Register Map — PWM 8-Channel Controller
// ============================================================================
//  Addr   Name        R/W   Width   Description
// ------  ----------  ---   -----   -----------------------------------------
//  0x00   PRE_L       R/W     8     Prescaler low byte
//  0x01   PRE_H       R/W     8     Prescaler high bits (use only [1:0], other bits are reserved)
//  0x02   DUTY_CH0    R/W     8     Duty cycle channel 0
//  0x03   DUTY_CH1    R/W     8     Duty cycle channel 1
//  0x04   DUTY_CH2    R/W     8     Duty cycle channel 2
//  0x05   DUTY_CH3    R/W     8     Duty cycle channel 3
//  0x06   DUTY_CH4    R/W     8     Duty cycle channel 4
//  0x07   DUTY_CH5    R/W     8     Duty cycle channel 5
//  0x08   DUTY_CH6    R/W     8     Duty cycle channel 6
//  0x09   DUTY_CH7    R/W     8     Duty cycle channel 7
//  0x0A   PHASE_CH0   R/W     8     Phase offset channel 0
//  0x0B   PHASE_CH1   R/W     8     Phase offset channel 1
//  0x0C   PHASE_CH2   R/W     8     Phase offset channel 2
//  0x0D   PHASE_CH3   R/W     8     Phase offset channel 3
//  0x0E   PHASE_CH4   R/W     8     Phase offset channel 4
//  0x0F   PHASE_CH5   R/W     8     Phase offset channel 5
//  0x10   PHASE_CH6   R/W     8     Phase offset channel 6
//  0x11   PHASE_CH7   R/W     8     Phase offset channel 7
//  0x12   ENABLE      R/W     8     Output enable mask [7:0] (1 = enabled)
//  0x13   DEADTIME    R/W     8     Dead‑time cycles (0 = disabled)
//  0x14   FAULT_CLR   W       8     Write 1 to clear fault latch (auto‑clears)
//  0x15   STATUS      R       8     Fault status – bit0 = fault_latch (read only)
//  0x16   DEVICE_ID   R       8     Device identifier – fixed 0x50 (read only)
// ============================================================================

module register_file #(
    parameter N_CH       = 8,
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
    output     [7:0]  enable,
    output     [7:0]  deadtime,
    output            fault_clr
);

    reg [7:0] PRE_L;
    reg [7:0] PRE_H;
    reg [7:0] DUTY    [0:N_CH-1];
    reg [7:0] PHASE   [0:N_CH-1];
    reg [7:0] ENABLE;
    reg [7:0] DEADTIME;
    reg [7:0] FAULT_CLR;
    reg [7:0] STATUS;

    integer j;

    // Write logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            PRE_L    <= 8'h00;
            PRE_H    <= 8'h00;
            for (j = 0; j < N_CH; j = j+1) begin
                DUTY[j]  <= 8'h00;
                PHASE[j] <= 8'h00;
            end
            ENABLE   <= 8'hFF;
            DEADTIME <= 8'h00;
            FAULT_CLR <= 8'h00;
            STATUS   <= 8'h00;
        end
        else begin
            // Auto-clear FAULT_CLR after 1 cycle
            FAULT_CLR <= 8'h00;
            // Update STATUS from fault_in
            STATUS <= {7'b0, fault_in};
			
            if (reg_we) begin
                case (reg_addr)
                    5'h00: PRE_L     <= reg_wdata;
                    5'h01: PRE_H     <= reg_wdata;
                    5'h02: DUTY[0]   <= reg_wdata;
                    5'h03: DUTY[1]   <= reg_wdata;
                    5'h04: DUTY[2]   <= reg_wdata;
                    5'h05: DUTY[3]   <= reg_wdata;
                    5'h06: DUTY[4]   <= reg_wdata;
                    5'h07: DUTY[5]   <= reg_wdata;
                    5'h08: DUTY[6]   <= reg_wdata;
                    5'h09: DUTY[7]   <= reg_wdata;
                    5'h0A: PHASE[0]  <= reg_wdata;
                    5'h0B: PHASE[1]  <= reg_wdata;
                    5'h0C: PHASE[2]  <= reg_wdata;
                    5'h0D: PHASE[3]  <= reg_wdata;
                    5'h0E: PHASE[4]  <= reg_wdata;
                    5'h0F: PHASE[5]  <= reg_wdata;
                    5'h10: PHASE[6]  <= reg_wdata;
                    5'h11: PHASE[7]  <= reg_wdata;
                    5'h12: ENABLE    <= reg_wdata;
                    5'h13: DEADTIME  <= reg_wdata;
                    5'h14: FAULT_CLR <= reg_wdata;
                    // 0x15 STATUS   — read only, ignore
                    // 0x16 DEVICE_ID — read only, ignore
                    default: ;
                endcase
            end
        end
    end

    //Read logic
    always @* begin
        case (reg_addr)
            5'h00: reg_rdata = PRE_L;
            5'h01: reg_rdata = PRE_H;
            5'h02: reg_rdata = DUTY[0];
            5'h03: reg_rdata = DUTY[1];
            5'h04: reg_rdata = DUTY[2];
            5'h05: reg_rdata = DUTY[3];
            5'h06: reg_rdata = DUTY[4];
            5'h07: reg_rdata = DUTY[5];
            5'h08: reg_rdata = DUTY[6];
            5'h09: reg_rdata = DUTY[7];
            5'h0A: reg_rdata = PHASE[0];
            5'h0B: reg_rdata = PHASE[1];
            5'h0C: reg_rdata = PHASE[2];
            5'h0D: reg_rdata = PHASE[3];
            5'h0E: reg_rdata = PHASE[4];
            5'h0F: reg_rdata = PHASE[5];
            5'h10: reg_rdata = PHASE[6];
            5'h11: reg_rdata = PHASE[7];
            5'h12: reg_rdata = ENABLE;
            5'h13: reg_rdata = DEADTIME;
            5'h14: reg_rdata = FAULT_CLR;
            5'h15: reg_rdata = STATUS;
            5'h16: reg_rdata = 8'h50;  // DEVICE_ID hardcoded
            default: reg_rdata = 8'h00;
        endcase
    end

    //Output assignments
    assign pre_div   = {PRE_H[1:0], PRE_L};
    assign enable    = ENABLE;
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