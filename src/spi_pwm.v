module spi_pwm (
	input clk,
	input rst_n,
	input sck,
	input mosi,
	input cs_n,
	input  [7:0] reg_rdata,
	
	output miso,
	output reg [4:0] reg_addr,
	output reg [7:0] reg_wdata,
	output reg reg_we
);
	localparam IDLE =0;
	localparam GET_ADDR =1;
	localparam GET_DATA =2;
	localparam EXECUTE =3;
	localparam SEND_DATA =4;

	reg [2:0] state, next_state, cnt;
	reg [7:0] shift_reg;
	
	reg sck_ff1, sck_ff2, sck_ff3;
	reg cs_ff1,  cs_ff2,  cs_ff3;
	wire sck_rise,sck_fall,cs_fall,cs_rise;
	
	always @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			sck_ff1 <= 0;
			sck_ff2 <= 0;
			sck_ff3 <= 0;
			cs_ff1  <= 1; 
			cs_ff2  <= 1;
			cs_ff3  <= 1;
		end else begin
			sck_ff1 <= sck;
			sck_ff2 <= sck_ff1;
			sck_ff3 <= sck_ff2;

			cs_ff1  <= cs_n;
			cs_ff2  <= cs_ff1;
			cs_ff3  <= cs_ff2;
		end
	end

	// Edge detection
	assign sck_rise = sck_ff2 & ~sck_ff3;
	assign sck_fall = ~sck_ff2 & sck_ff3;
	assign cs_fall  = ~cs_ff2  & cs_ff3;   // CS_n falling = start
	assign cs_rise  =  cs_ff2  & ~cs_ff3;  // CS_n rising  = abort
	
	always @(*) begin
		case(state)
			IDLE: next_state = cs_fall ? GET_ADDR  : IDLE;
			GET_ADDR: next_state = cs_rise ? IDLE : (cnt == 7 && sck_rise) ? (shift_reg[6] ? SEND_DATA : GET_DATA) : GET_ADDR;
			GET_DATA: next_state = cs_rise ? IDLE : (cnt ==7 && sck_rise) ? EXECUTE : GET_DATA;
			SEND_DATA: next_state = cs_rise ? IDLE : (cnt ==7 && sck_fall) ? IDLE : SEND_DATA;
			EXECUTE: next_state = IDLE;
			default:   next_state = IDLE;
		endcase
	end
	
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
			state <=IDLE;
		end
		else begin
			state <= next_state;
		end
	end
	
	always @(posedge clk) begin
		if (state != SEND_DATA && next_state == SEND_DATA)
			shift_reg <= reg_rdata;

		else if (sck_rise && state == IDLE) begin
			cnt   <= 0;
		end

		else if (sck_rise && state == GET_ADDR) begin
			shift_reg <= {shift_reg[6:0], mosi};
			if (cnt == 7) begin
				reg_addr <= {shift_reg[3:0], mosi};
				cnt      <= 0;
			end else
				cnt <= cnt + 1;
		end

		else if (sck_rise && state == GET_DATA) begin
			shift_reg <= {shift_reg[6:0], mosi};
			if (cnt == 7) begin
				reg_wdata <= {shift_reg[6:0], mosi};
				cnt       <= 0;
			end else
				cnt <= cnt + 1;
		end

		else if (sck_fall && state == SEND_DATA) begin
			shift_reg <= {shift_reg[6:0], 1'b0};
			if (cnt == 7) cnt <= 0;
			else cnt <= cnt + 1;
		end
	end

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			reg_we <= 1'b0;
		else
			reg_we <= (state == EXECUTE);
	end
	
	assign miso = (state == SEND_DATA) ? shift_reg[7] : 1'bz;
	
endmodule
