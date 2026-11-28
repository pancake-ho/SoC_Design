// Independent watchdog remains alive even if a driver task stops advancing.
initial begin
    repeat(40000000) @(posedge clk);
    $display("TIMEOUT case=%0s independent_watchdog",case_name);
    $fatal(1,"testbench watchdog");
end

always @(posedge clk) begin
    cycle_count=cycle_count+1;
    clk_edge_ps=now_ps();
    if(rst_n && host_valid && busy) protocol_errors=protocol_errors+1;
    if(rst_n && start && !busy && boot_addr==0) begin
        cpu_start_cycle=cycle_count; cpu_cycles=0;
    end
    if(rst_n && commit_valid !== 1'b0 && (commit_valid !== 1'b1 || busy !== 1'b1))
        protocol_errors=protocol_errors+1;
    if(rst_n && commit_valid) begin
        if(case_name=="F12") begin
            if(commit_pc==cpu_start_pc) cpu_start_stores=cpu_start_stores+1;
            check_f12_readback_commit;
        end
        if(trace_enabled) begin
            if(trace_index>=trace_words[0]) check32("excess_cpu_commit",0,1);
            else begin
                check32("commit_pc",trace_words[1+trace_index*4],commit_pc);
                check32("commit_instruction",trace_words[2+trace_index*4],commit_insn);
                check32("commit_destination",trace_words[3+trace_index*4],{27'b0,commit_rd});
                check32("commit_value",trace_words[4+trace_index*4],commit_wdata);
            end
            trace_index=trace_index+1;
        end
    end
    #(clk_period_ps/10000.0);
    if(!rst_n) cpu_start_cycle=0;
    else begin
        if(done && cpu_start_cycle!=0 && cpu_cycles==0) cpu_cycles=cycle_count-cpu_start_cycle;
        if(reserved_out[0] && reserved_out[1]) protocol_errors=protocol_errors+1;
    end
end
