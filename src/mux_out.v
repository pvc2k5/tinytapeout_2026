module mux_out #(
	parameter N_CH = 4
)(
	input [N_CH-1:0] pwm_h,
	input [N_CH-1:0] pwm_l,
	input [N_CH-1:0] enable,
	input shutdown,
	output [N_CH-1:0] out_h,
	output [N_CH-1:0] out_l
);
	
	genvar i;
	generate
		for(i=0;i<N_CH;i=i+1) begin : gen_mux
			assign out_h[i] = pwm_h[i] & enable[i] & ~shutdown;
			assign out_l[i] = pwm_l[i] & enable[i] & ~shutdown;
		end
	endgenerate
endmodule
