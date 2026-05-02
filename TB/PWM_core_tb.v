`timescale 1ns/1ps
module PWM_core_tb();
    localparam DATA_WIDTH = 8;
    localparam N_CH = 8;
    reg clk;
    reg rst_n;
    reg pwm_clk_en;
    reg [N_CH*DATA_WIDTH-1:0] dc;
    reg [N_CH*DATA_WIDTH-1:0] phase];
    wire [N_CH-1:0] raw;
	
    pwm_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .N_CH(N_CH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .pwm_clk_en(pwm_clk_en),
        .dc(dc),
        .phase(phase),
        .raw(raw)
    );

    initial begin
        clk = 0;
        forever #50 clk = ~clk;
    end

    task check_rs();
        begin
            rst_n = 0;
            pwm_clk_en = 0;
            repeat(3) @(posedge clk);
            if (raw !== {N_CH{1'b0}}) begin
                $display("RESET FAILED: raw=%b", raw);
                $finish;
            end
            rst_n = 1;
            repeat(2) @(posedge clk);
        end
    endtask

    task run_and_count(
        input integer n,
        input integer ch,
        output integer cnt_high
    );
        integer i;
        begin
            cnt_high = 0;
            for(i = 0; i < n; i = i+1) begin
                @(posedge clk);
                pwm_clk_en = 1;
                @(posedge clk);
                pwm_clk_en = 0;
                if(raw[ch]) cnt_high = cnt_high + 1;
            end
        end
    endtask

    task check_duty(
        input integer ch,
        input integer expected
    );
        integer h;
        begin
            run_and_count(256, ch, h);
            if(h !== expected) begin
                $display("DUTY FAILED ch=%0d: expected=%0d actual=%0d", ch, expected, h);
                $finish;
            end else begin
                $display("DUTY OK ch=%0d: duty=%0d", ch, expected);
            end
        end
    endtask

    integer i;
    initial begin
        $dumpfile("dump.vcd");
        $dumpvars(0, dut);

        for(i=0; i<N_CH; i=i+1) begin
            dc[i]    = 0;
            phase[i] = 0;
        end
        pwm_clk_en = 0;

        check_rs;

        dc[0] = 0; phase[0] = 0;
        check_duty(0, 0);

        dc[0] = 128; phase[0] = 0;
        check_duty(0, 128);

        dc[0] = 255; phase[0] = 0;
        check_duty(0, 256);

        dc[0] = 64; phase[0] = 128;
        check_duty(0, 64);

        phase[0] = 0;
        for(i=0; i<N_CH; i=i+1) begin
            dc[i] = 32*i;
			phase[i] = 32*i;
		end
		
        for(i=0; i<N_CH; i=i+1)
            check_duty(i, 32*i);

        dc[0] = 200;
        check_duty(1, 32); 

        $display("ALL TESTS PASSED");
        $finish;
    end

    initial begin
        #10000000;
        $display("ERROR: Watchdog timeout");
        $finish;
    end
	
endmodule