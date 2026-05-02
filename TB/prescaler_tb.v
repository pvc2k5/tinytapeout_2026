`timescale 1ns/1ps

module prescaler_tb();
	reg clk;
	reg rst_n;
	reg [9:0] div;
	wire pwm_clk_en;
	
	real freq_e;
  
	prescaler dut(
		.clk(clk),
		.rst_n(rst_n),
		.div(div),
		.pwm_clk_en(pwm_clk_en)
	);
	
	initial begin
		clk =0;
		forever #50 clk = ~clk;
	end
	
	task cal_freq_e ();
		begin
		freq_e = 10000.0/(div+1);
		end
	endtask
	task check_rs ();
		begin
		rst_n = 1'b0;
		repeat(3) @(posedge clk);
		if (pwm_clk_en !== 1'b0) begin
			$display("Reset Failed");
			$display("[%t] Expected reset value: 0 \n Actual reset value: %b",$time,pwm_clk_en);
			$finish;
		end
		rst_n =1'b1;
		end
	endtask
	
	task check_freq_pwm ();
		real t1,t2, freq;
		begin
			@(posedge pwm_clk_en);
			t1= $time;
			@(posedge pwm_clk_en);
			t2= $time;
			freq = 1_000_000.0/(t2-t1);
          	if(freq < freq_e - 0.001 || freq > freq_e + 0.001) begin
				$display("TEST FAILED");
				$display("[%t] Expected Frequency: %d \n Actual Frequency: %d",$time,freq_e, freq);
				$finish;
			end
          else $display("OK");
		end
	endtask
	
	initial begin
      	$dumpfile("dump.vcd");
      	$dumpvars(0,dut);
		check_rs;
		div = 10'd1023;
		cal_freq_e;
		check_freq_pwm;
      	#500000;
		check_rs;
		div = 10'd99;
		cal_freq_e;
		check_freq_pwm;
      	#50000;
		check_rs;
		div = 10'd1;
		cal_freq_e;
		check_freq_pwm;
		$display("TEST PASSED");
		$finish;
	end
  	initial begin //WATCHDOG
    	#10000000;
      	$display("ERROR: Watchdog timeout");
    	$finish;
	end
endmodule