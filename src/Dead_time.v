module dead_time
	#(
		DATA_WIDTH =8
	)
	(
	input clk,
	input rst_n,
	input pwm_in,
	input [DATA_WIDTH-1:0] dt_cycles,
	output reg pwm_h,
	output reg pwm_l
);
	localparam IDLE_L = 0;
	localparam IDLE_H = 1;
	localparam WAIT_L = 2;
	localparam WAIT_H = 3;
	
	reg [1:0] state, next_state;
	reg [DATA_WIDTH-1:0] cnt;
	
	always @* begin
		case(state)
			IDLE_L: next_state = pwm_in ? WAIT_H : IDLE_L;
			WAIT_H: next_state = (cnt == dt_cycles - 1) ? IDLE_H : WAIT_H;
			IDLE_H: next_state = pwm_in ? IDLE_H : WAIT_L;
			WAIT_L: next_state = (cnt == dt_cycles - 1) ? IDLE_L : WAIT_L;
		endcase
	end
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			state <= IDLE_L;
			cnt   <= '0;
		end else begin
			state <= next_state;
			if (next_state != state && (next_state == WAIT_H || next_state == WAIT_L))
				cnt <= '0;
			else if (state == WAIT_H || state == WAIT_L)
				cnt <= cnt + 1'b1;
		end
	end

	always @* begin
		pwm_h = (state == IDLE_H);
		pwm_l = (state == IDLE_L);
	end
	
endmodule