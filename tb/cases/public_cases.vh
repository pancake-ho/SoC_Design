task case_isa;
    reg [31:0] value;
    begin
        bus_write(32'h20000,32'h80000000); bus_write(32'h20004,32'h7fffffff); bus_write(32'h20008,32'h600d);
        bus_write(36,SENTINEL); bus_write(40,SENTINEL); bus_write(48,SENTINEL);
        bus_write(240,0);
        preload_program(program_count);
        bus_read(32'h10000,value); check32("imem_first_word",program_words[0],value);
        bus_read(32'h10000+4*(program_count-1),value);
        check32("imem_last_word",program_words[program_count-1],value);
        trace_enabled=1; run_cpu; trace_enabled=0;
        check32("exact_commit_count",trace_words[0],trace_index);
        bus_read(32,value); check32("dmem_positive_offset_store",17,value);
        bus_read(48,value); check32("dmem_negative_offset_store",32'h7fffffff,value);
        bus_read(36,value); check32("dmem_taken_branch_skips_store",SENTINEL,value);
        bus_read(40,value); check32("dmem_jal_skips_store",SENTINEL,value);
        bus_read(240,value); check32("cpu_signature",32'h600d,value);
    end
endtask

task case_memory;
    integer j;
    reg [31:0] value,previous;
    begin
        for(j=0;j<CNN_WORDS;j=j+1) if(active_word(j)) sram_write(4*j,32'h13570000+j*131);
        for(j=0;j<CNN_WORDS;j=j+1) if(active_word(j)) begin
            sram_read(4*j,value); check32("all_word_alias_test",32'h13570000+j*131,value);
        end
        previous=value; sram_write(4*X_BASE,32'h1234); bus_read(MMIO+28,value);
        check32("write_keeps_last_read",previous,value);
    end
endtask

task case_busy;
    reg [31:0] status,value;
    reg config_write_while_busy;
    begin
        bus_write(MMIO+12,4*X_BASE); bus_write(MMIO+16,32'h12345678);
        reserved_in=8; bus_write(MMIO+20,6);
        bus_write(MMIO+12,4*X_BASE+4); bus_write(MMIO+16,32'hdeadbeef); bus_write(MMIO,1);
        bus_read(MMIO+4,value); check32("start_during_cpu_transfer_rejected",4,value);
        wait_transfer(status); check32("busy_transfer_error_sticky",6,status);
        reserved_in=0;
        bus_read(MMIO+12,value); check32("busy_address_write_rejected",4*X_BASE,value);
        bus_read(MMIO+16,value); check32("busy_data_write_rejected",32'h12345678,value);
        sram_read(4*X_BASE,value); check32("accepted_transfer_keeps_payload",32'h12345678,value);
        load_frame(0); bus_write(MMIO,1);
        bus_write(MMIO+8,0);
        config_write_while_busy=last_host_accepted_while_npu_busy;
        bus_read(MMIO+8,value);
        check32("config_write_follows_public_busy",config_write_while_busy ? vectors[1] : 0,value);
        wait_npu(status);
        check32("active_frame_completes",config_write_while_busy ? 6 : 2,status);
        verify_frame(0);
    end
endtask

task case_invalid_address;
    integer j;
    reg [31:0] status,value,address;
    begin
        bus_read(MMIO,value); check32("write_only_ctrl_reads_zero",0,value);
        bus_read(MMIO+20,value); check32("write_only_cmd_reads_zero",0,value);
        bus_write(MMIO+4,32'hffffffff); bus_read(MMIO+4,value); check32("read_only_status_write_ignored",0,value);
        bus_write(MMIO+8,32'hffffffff); bus_read(MMIO+8,value); check32("config_reserved_bits_zero",32'hf3,value);
        for(j=0;j<CNN_WORDS;j=j+1) if(active_word(j)) sram_write(4*j,SENTINEL);
        for(j=0;j<6;j=j+1) begin
            case(j)
                0: address=1; 1: address=8192; 2: address=32'h10000000;
                3: address=32'hfffffffc; 4: address=1280; default: address=4*X_BASE;
            endcase
            bus_write(MMIO+12,address); bus_write(MMIO+16,32'hdeadbeef);
            bus_write(MMIO+20,j==5 ? 7 : 6); wait_transfer(status);
            check32("invalid_request_rejected",4,status);
        end
        for(j=0;j<CNN_WORDS;j=j+1) if(active_word(j)) begin
            sram_read(j*4,value); check32("invalid_request_no_corruption",SENTINEL,value);
        end
    end
endtask

task case_reset;
    reg [31:0] value;
    begin
        load_frame(0); bus_write(MMIO,1);
        reset_dut;
        bus_read(MMIO+4,value); check32("reset_status",0,value);
        bus_read(MMIO+8,value); check32("reset_config",32'h23,value);
        verify_inputs(0);
        run_frame(0); run_frame(0);
    end
endtask

task case_faults;
    reg [31:0] status;
    integer j;
    begin
        reserved_in=3; run_frame(0); reserved_in=0;
        for(j=0;j<3;j=j+1) begin
            bus_write(MMIO+12,4*X_BASE);
            reserved_in=j==0 ? 16 : j==1 ? 32 : 64;
            bus_write(MMIO+20,5); wait_transfer(status); check32("transfer_fault_or_timeout",4,status);
            reset_dut;
        end
        for(j=0;j<2;j=j+1) begin
            load_frame(0); reserved_in=j==0 ? 16 : 64;
            bus_write(MMIO,1); wait_npu(status); check32("npu_fault_or_timeout",4,status); reset_dut;
        end
        run_frame(0);
    end
endtask

task case_integration;
    integer j;
    reg [31:0] value;
    begin
        load_frame(0);
        preload_program(program_count);
        bus_write(32'h20000,{24'b0,vectors[1][7:0]});
        value=0;
        for(j=0;j<2*OUT_WORDS;j=j+1) value=value+vectors[298+j];
        bus_write(32'h20004,value);
        bus_write(32'h20008,32'h600d); bus_write(32'h2000c,32'hbad);
        bus_write(240,0);
        workload_load_complete_ps=now_ps();
        measure_next_reset=1;
        reset_dut;
        measure_next_reset=0;
        run_cpu;
        bus_read(240,value); check32("integration_cpu_signature",32'h600d,value);
        check32("cpu_issued_start_exactly_once",1,cpu_start_stores);
        check32("cpu_run_measured",1,cpu_cycles>0);
        verify_inputs(0);
    end
endtask

task run_public_case;
    integer frame;
    begin
        if(case_name=="F01") case_isa;
        else if(case_name=="F02") case_memory;
        else if(case_name=="F08") case_busy;
        else if(case_name=="F09") case_invalid_address;
        else if(case_name=="F10") case_reset;
        else if(case_name=="F11") case_faults;
        else if(case_name=="F12") case_integration;
        else begin
            for(frame=0;frame<vectors[0];frame=frame+1) run_frame(frame);
        end
    end
endtask
