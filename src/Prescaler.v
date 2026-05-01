module prescaler (
	input clk,
	input rst_n,
	input [9:0] div,
	output reg pwm_clk_en
);
	reg [9:0] cnt;
	always @(posedge clk or negedge rst_n) begin
		if(!rst_n) begin
          	cnt <= '0;
		end
      	else if(cnt == div) begin
			cnt <= '0;
		end
		else begin
			cnt <= cnt +1'b1;
		end
	end
	
  always @*begin
    pwm_clk_en = (cnt==div);;
  end
endmodule
