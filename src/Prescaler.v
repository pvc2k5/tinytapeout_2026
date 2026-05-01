module prescaler (
	input  clk,
	input  rst_n,
	input  [9:0] div,
	output pwm_clk_en
);
	reg [9:0] cnt;

	always @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			cnt <= 10'b0;
		else if (cnt >= div)
			cnt <= 10'b0;
		else
			cnt <= cnt + 1'b1;
	end

	assign pwm_clk_en = (cnt == div);

endmodule
