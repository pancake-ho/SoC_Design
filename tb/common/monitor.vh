// Independent watchdog remains alive even if a driver task stops advancing.
initial begin
    repeat(40000000) @(posedge clk);
    $display("TIMEOUT case=%0s independent_watchdog",case_name);
    $fatal(1,"testbench watchdog");
end

always @(posedge clk) begin
    cycle_count=cycle_count+1;
    clk_edge_ps=now_ps();
    if(!rst_n) begin memory_outstanding=0; outstanding_npu=0; request_stalled=0; end
    else begin
        if(observe_response) begin
            if(!memory_outstanding) protocol_errors=protocol_errors+1;
            memory_outstanding=0;
        end
        if(request_stalled && observe_valid && held_request !== {observe_write,observe_address,observe_wdata})
            protocol_errors=protocol_errors+1;
        request_stalled=observe_valid && !observe_ready;
        held_request={observe_write,observe_address,observe_wdata};
        if(observe_accept) begin
            if(memory_outstanding) protocol_errors=protocol_errors+1;
            memory_outstanding=1; outstanding_npu=observe_npu_owner;
            if(observe_npu_owner && !observe_write) cnn_reads=cnn_reads+1;
            if(observe_npu_owner && observe_write) cnn_writes=cnn_writes+1;
            // Scratch and result words can be written. Common inputs must be preserved.
            if(observe_npu_owner && observe_write && input_slot(observe_address)>=0)
                protocol_errors=protocol_errors+1;
        end
    end
    if(rst_n && host_valid && busy) protocol_errors=protocol_errors+1;
    if(rst_n && start && !busy && boot_addr==0) begin
        cpu_start_cycle=cycle_count; cpu_cycles=0;
    end
    if(rst_n && commit_valid !== 1'b0 && (commit_valid !== 1'b1 || busy !== 1'b1))
        protocol_errors=protocol_errors+1;
    if(rst_n && commit_valid) begin
        if(case_name=="F12" && commit_pc==cpu_start_pc) cpu_start_stores=cpu_start_stores+1;
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
    if(!rst_n) begin
        previous_npu_done=0; previous_npu_busy=0; cpu_start_cycle=0;
    end
    else begin
        if(done && cpu_start_cycle!=0 && cpu_cycles==0) cpu_cycles=cycle_count-cpu_start_cycle;
        if(reserved_out[0] && !previous_npu_busy) begin
            cnn_start_cycle=cycle_count; cnn_reads=0; cnn_writes=0;
            if(case_name=="F12" && busy) cpu_npu_starts=cpu_npu_starts+1;
        end
        if(reserved_out[0] && reserved_out[1]) protocol_errors=protocol_errors+1;
        if(reserved_out[1] && !previous_npu_done) begin
            last_cnn_cycles=cycle_count-cnn_start_cycle; last_cnn_reads=cnn_reads; last_cnn_writes=cnn_writes;
            if(memory_outstanding && outstanding_npu) protocol_errors=protocol_errors+1;
        end
        previous_npu_done=reserved_out[1]; previous_npu_busy=reserved_out[0];
    end
end
