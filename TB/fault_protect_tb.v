module fault_protection_tb();
	logic       clk,rst_n,n_fault,fault_clr,fault_latch,shutdown;
	
	fault_protection dut(
		.clk(clk),
		.rst_n(rst_n),
		.n_fault(n_fault),
		.fault_clr(fault_clr),
		.fault_latch(fault_latch),
		.shutdown(shutdown)
	);
	
	initial begin
		clk = 0;
		forever #50 clk = ~clk;
	end
	
	task check_rs ();
		begin
		rst_n = 1'b0;
		repeat(3) @(posedge clk);
		if (dut.state !== 1'b0) begin
			$display("Reset Failed");
			$display("[%t] Expected state reset value: 0 \n Actual state reset value: %d",$time,dut.state);
			$finish;
		end
		rst_n =1'b1;
		repeat(2) @(posedge clk);
		end
	endtask
	
	task check_e(
		input out,
		input out_e,
	);
		begin
			if(out !== out_e) begin
				$display("TEST FAILED \n [%t] Expected value = %d, Actual value = %d", $time, out_e, out);
				$finish;
			end
			else $display("[%t] TEST OK Value = %d", $time, out);
		end
	endtask
	
	initial begin
		n_fault =1'b1;
		fault_clr =1'b0;
		check_rs;
		
		n_fault =1'b0;
		@(posedge clk);
		n_fault = 1'b1;
		check_e(fault_latch,1);
		check_e(shutdown,1);
		
		fault_clr = 1'b1;
		check_e(fault_latch,0);
		check_e(shutdown,0);
		
		$display("ALL TEST PASSED");
	end
endmodule