`timescale 1ns/1ps

module mux_out_tb();
    localparam N_CH =8;
    reg [N_CH-1:0] pwm_h;
    reg [N_CH-1:0] pwm_l;
    reg [N_CH-1:0] enable;
    reg shutdown;
    wire [N_CH-1:0] out_h;
    wire [N_CH-1:0] out_l;
	
	mux_out #(.N_CH(N_CH)) dut
	(
		.pwm_h(pwm_h),
		.pwm_l(pwm_l),
		.enable(enable),
		.shutdown(shutdown),
		.out_h(out_h),
		.out_l(out_l)
	);
	reg clk;
	initial begin
		clk =0;
		forever #50 clk =~clk;
	end
	
	task check_e(
		input out,
		input out_e
	);
		begin
			if(out !== out_e) begin
				$display("TEST FAILED \n [%t] Expected out: %b, Actual out: %b",$time,out,out_e);
				$finish;
			end
		end
	endtask
	
	initial begin
		enable =1;
		shutdown =0;
		pwm_h = 1;//assume all channel tied to high;
		pwm_l =0;//assume all channel tied to low;
		repeat(3) @(posedge clk);
		check_e(out_h,1);
		check_e(out_l,0);
		@(posedge clk);
		
		pwm_h = 0;//assume all channel tied to low;
		pwm_l =1;//assume all channel tied to high;
		repeat(3) @(posedge clk);
		check_e(out_h,0);
		check_e(out_l,1);
		
		@(posedge clk);
		shutdown =1;
		repeat(3) @(posedge clk);
		check_e(out_h,0);
		check_e(out_l,0);
		shutdown =0;
		enable =0;
		repeat(3) @(posedge clk);
		check_e(out_h,0);
		check_e(out_l,0);
		
		$display("ALL TEST PASSED");
		$finish;
	end
endmodule