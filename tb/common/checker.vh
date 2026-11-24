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
            check32("cnn_pin_checkpoint_pair",1,cnn_busy_ps>=0 && cnn_done_ps>cnn_busy_ps && cnn_done_cycle>cnn_busy_cycle);
            check32("cnn_clock_interval_matches_period",1,
                cnn_done_clk_ps-cnn_busy_clk_ps == (cnn_done_cycle-cnn_busy_cycle)*longint'(clk_period_ps));
        end
        check32("no_protocol_errors",0,protocol_errors);
        $display("SUMMARY case=%0s checks=%0d errors=%0d cycles=%0d",case_name,checks,errors,cycle_count);
        report=$fopen("raw_result.json","w");
        $fwrite(report,"{\"case_id\":\"%0s\",\"checks\":%0d,\"errors\":%0d,\"cycles\":%0d,",case_name,checks,errors,cycle_count);
        $fwrite(report,"\"normal_completion\":true,\"protocol_errors\":%0d,\"cnn_cycles\":%0d,",protocol_errors,last_cnn_cycles);
        $fwrite(report,"\"first_failure\":\"%0s\",\"cpu_start_stores\":%0d,\"cnn_reads\":%0d,",first_failure,cpu_start_stores,last_cnn_reads);
        $fwrite(report,"\"cpu_cycles\":%0d,\"cpu_npu_starts\":%0d,",cpu_cycles,cpu_npu_starts);
        $fwrite(report,"\"cnn_writes\":%0d,\"macs_per_frame\":7056,\"output_count\":784,",last_cnn_writes);
        $fwrite(report,"\"clock_period_ps\":%0d,\"clock_latency_ps\":%0d,",clk_period_ps,clk_latency_ps);
        if(case_name=="F12") begin
            $fwrite(report,"\"injected_abs_delay_ps\":%0d,",checkpoint_injected_ps);
            $fwrite(report,"\"npu_busy_ps\":%0d,\"npu_done_ps\":%0d,",cnn_busy_ps,cnn_done_ps);
            $fwrite(report,"\"npu_busy_cycle\":%0d,\"npu_done_cycle\":%0d,",cnn_busy_cycle,cnn_done_cycle);
            $fwrite(report,"\"npu_busy_edge_ps\":%0d,\"npu_done_edge_ps\":%0d,",cnn_busy_clk_ps,cnn_done_clk_ps);
        end
        $fwrite(report,"\"overflow_frames_passed\":%0d}\n",overflow_frames_passed);
        $fclose(report);
        if(errors!=0) $fatal(1,"official checker failed");
        $finish;
    end
endtask
