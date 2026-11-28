task check32;
    input [8*48-1:0] label;
    input [31:0] expected,actual;
    begin
        checks=checks+1;
        if(actual !== expected) begin
            errors=errors+1;
            if(first_failure==0) first_failure=label;
            $display("CHECK_FAIL case=%0s point=%0s exp=%08h got=%08h cycle=%0d",
                case_name,label,expected,actual,cycle_count);
        end
    end
endtask

task finish_case;
    integer report;
    begin
        if(case_name=="F12") begin
            check32("workload_checkpoint_order",1,workload_load_complete_ps>=0 &&
                workload_load_complete_ps<workload_reset_ps &&
                workload_first_clk_ps>workload_reset_ps &&
                cnn_busy_ps>=workload_first_clk_ps && cnn_done_ps>cnn_busy_ps);
            check32("f12_npu_done_once",1,cnn_done_rises);
            check32("f12_lw_count",F12_RESULT_COUNT,f12_lw_count);
            check32("f12_readback_complete",0,f12_phase);
        end
        check32("no_protocol_errors",0,protocol_errors);
        $display("SUMMARY case=%0s checks=%0d errors=%0d cycles=%0d",case_name,checks,errors,cycle_count);
        report=$fopen("raw_result.json","w");
        $fwrite(report,"{\"case_id\":\"%0s\",\"checks\":%0d,\"errors\":%0d,\"cycles\":%0d,",case_name,checks,errors,cycle_count);
        $fwrite(report,"\"normal_completion\":true,\"protocol_errors\":%0d,",protocol_errors);
        $fwrite(report,"\"first_failure\":\"%0s\",\"cpu_start_stores\":%0d,",first_failure,cpu_start_stores);
        $fwrite(report,"\"cpu_cycles\":%0d,",cpu_cycles);
        $fwrite(report,"\"macs_per_frame\":7056,\"output_count\":784,");
        $fwrite(report,"\"clock_period_ps\":%0d,\"clock_latency_ps\":%0d,",clk_period_ps,clk_latency_ps);
        if(case_name=="F12") begin
            $fwrite(report,"\"workload_reset_ps\":%0d,\"workload_first_clk_ps\":%0d,",workload_reset_ps,workload_first_clk_ps);
            $fwrite(report,"\"workload_load_complete_ps\":%0d,",workload_load_complete_ps);
            $fwrite(report,"\"injected_abs_delay_ps\":%0d,",checkpoint_injected_ps);
            $fwrite(report,"\"npu_busy_ps\":%0d,\"npu_done_ps\":%0d,",cnn_busy_ps,cnn_done_ps);
            $fwrite(report,"\"npu_busy_cycle\":%0d,\"npu_done_cycle\":%0d,",cnn_busy_cycle,cnn_done_cycle);
            $fwrite(report,"\"npu_busy_edge_ps\":%0d,\"npu_done_edge_ps\":%0d,",cnn_busy_clk_ps,cnn_done_clk_ps);
            $fwrite(report,"\"npu_done_rises\":%0d,\"f12_lw_count\":%0d,",cnn_done_rises,f12_lw_count);
            $fwrite(report,"\"f12_first_lw_ps\":%0d,\"f12_last_lw_ps\":%0d,",f12_first_lw_ps,f12_last_lw_ps);
        end
        $fwrite(report,"\"overflow_frames_passed\":%0d}\n",overflow_frames_passed);
        $fclose(report);
        if(errors!=0) $fatal(1,"official checker failed");
        $finish;
    end
endtask
