module fault_protection (
    input  wire clk,
    input  wire rst_n,
    input  wire n_fault,
    input  wire fault_clr,
    output wire fault_latch,
    output wire shutdown
);
    // State encoding
    localparam NOR = 1'b0;
    localparam FAU = 1'b1;

    reg state, next_state;

    // Synchronizer
    reg n_fault_sync1, n_fault_sync2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            n_fault_sync1 <= 1'b1;
            n_fault_sync2 <= 1'b1;
        end else begin
            n_fault_sync1 <= n_fault;
            n_fault_sync2 <= n_fault_sync1;
        end
    end

    // Next state logic
    always @* begin
        case(state)
            NOR: next_state = !n_fault_sync2 ? FAU : NOR;
            FAU: next_state = (fault_clr && n_fault_sync2) ? NOR : FAU;
            default: next_state = NOR;
        endcase
    end

    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= NOR;
        else
            state <= next_state;
    end

    assign fault_latch = (state == FAU);
    assign shutdown    = (state == FAU) | ~n_fault;

endmodule