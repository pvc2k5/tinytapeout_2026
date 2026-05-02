module dead_time_tb();
	localparam DATA_WIDTH =8;
	reg clk;
	reg rst_n;
	reg pwm_in;
	reg [DATA_WIDTH-1:0] dt_cycles;
	wire pwm_h;
	wire pwm_l;
	
	dead_time #(
		.DATA_WIDTH(DATA_WIDTH)
	) dut (
		.clk(clk),
		.rst_n(rst_n),
		.pwm_in(pwm_in),
		.dt_cycles(dt_cycles),
		.pwm_h(pwm_h),
		.pwm_l(pwm_l)
	);
	
	initial begin
		clk =0;
		forever #50 clk = ~clk;
	end
	
	task gen_pwm(input integer duty, input integer cycles);
		integer i;
		begin
			for (i = 0; i < cycles; i = i+1) begin
				pwm_in = 1;
				repeat(duty) @(posedge clk);
				pwm_in = 0;
				repeat(256 - duty) @(posedge clk);
			end
		end
	endtask
	
	task check_deadtime_hl(input integer expected_cycles);
		real t1, t2;
		real measured;
		begin
			@(posedge pwm_h);
			@(negedge pwm_h) t1 = $realtime;		
			@(posedge pwm_l) t2 =$realtime;
			measured = (t2-t1)/100;
			if($abs(measured - expected_cycles) > 0.5) begin
				$display("DEADTIME FAILED: expected=%0d actual=%0f", 
						  expected_cycles, measured);
				$finish;
			end else
				$display("DEADTIME OK: %0f cycles", measured);
		end
	endtask
	
	task check_deadtime_lh(input integer expected_cycles);
		real t1, t2;
		real measured;
		begin
			@(posedge pwm_l);
			@(negedge pwm_l) t1 = $realtime;		
			@(posedge pwm_h) t2 =$realtime;
			measured = (t2-t1)/100;
			if($abs(measured - expected_cycles) > 0.5) begin
				$display("DEADTIME FAILED: expected=%0d actual=%0f", 
						  expected_cycles, measured);
				$finish;
			end else
				$display("DEADTIME OK: %0f cycles", measured);
		end
	endtask
	
	initial begin
      $dumpfile("dump.vcd");
      $dumpvars(0,dut);
		pwm_in   = 0;
		dt_cycles = 0;
		rst_n = 1'b0;
		repeat(3) @(posedge clk);
		rst_n =1'b1;
		repeat(2) @(posedge clk);
		dt_cycles = 10;
		fork
			gen_pwm(128, 10);
			check_deadtime_hl(10);
		join

		fork
			gen_pwm(128, 10);
			check_deadtime_lh(10);
		join

		$display("ALL TESTS PASSED");
		$finish;
	end
endmodule