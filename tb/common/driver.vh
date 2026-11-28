task reset_dut;
    begin
        @(negedge clk); rst_n=0; start=0; host_valid=0; reserved_in=0;
        repeat(3) @(negedge clk);
        rst_n=1;
        @(negedge clk);
    end
endtask

task wait_host_transfer;
    output [31:0] value;
    integer cycle;
    begin : wait_ready
        last_host_accepted_while_npu_busy=0;
        for(cycle=0;cycle<32;cycle=cycle+1) begin
            @(posedge clk);
            if(host_ready===1'b1) begin
                last_host_accepted_while_npu_busy=reserved_out[0]===1'b1;
                value=host_rdata;
                check32("host_access_error",0,host_error);
                disable wait_ready;
            end
        end
        value=32'hxxxxxxxx;
        check32("host_access_timeout",1,host_ready);
    end
endtask

task bus_write;
    input [31:0] address,value;
    reg [31:0] unused;
    begin
        @(negedge clk); host_addr=address; host_wdata=value; host_write=1; host_valid=1;
        wait_host_transfer(unused);
        @(negedge clk); host_valid=0; host_write=0;
    end
endtask

task bus_read;
    input [31:0] address;
    output [31:0] value;
    begin
        @(negedge clk); host_addr=address; host_write=0; host_valid=1;
        wait_host_transfer(value);
        @(negedge clk); host_valid=0;
    end
endtask

task wait_transfer;
    output [31:0] status;
    integer polls;
    begin : polling_transfer
        status=1;
        for(polls=0;polls<32;polls=polls+1) begin
            bus_read(MMIO+24,status);
            if(status[0]===1'b0) disable polling_transfer;
        end
        check32("transfer_watchdog",0,1);
    end
endtask

task sram_write;
    input [31:0] address,value;
    reg [31:0] status;
    begin
        bus_write(MMIO+12,address); bus_write(MMIO+16,value); bus_write(MMIO+20,6);
        wait_transfer(status); check32("sram_write_status",2,status);
    end
endtask

task sram_read;
    input [31:0] address;
    output [31:0] value;
    reg [31:0] status;
    begin
        bus_write(MMIO+12,address); bus_write(MMIO+20,5);
        wait_transfer(status); check32("sram_read_status",2,status);
        bus_read(MMIO+28,value);
    end
endtask

// Constant ROM uses canonical payload slots; the profile maps them into SRAM.
function integer input_slot;
    input integer word_index;
    begin
        if(word_index>=X_BASE && word_index<X_BASE+X_WORDS) input_slot=word_index-X_BASE;
        else if(word_index>=W_BASE && word_index<W_BASE+W_WORDS) input_slot=256+word_index-W_BASE;
        else if(word_index>=BIAS_BASE && word_index<BIAS_BASE+BIAS_WORDS) input_slot=292+word_index-BIAS_BASE;
        else input_slot=-1;
    end
endfunction

function active_word;
    input integer word_index;
    begin
        active_word=input_slot(word_index)>=0 || (word_index>=RAW_BASE && word_index<Y_BASE+OUT_WORDS);
    end
endfunction

task initialize_outputs;
    integer j;
    begin
        for(j=RAW_BASE;j<Y_BASE+OUT_WORDS;j=j+1) sram_write(j*4,SENTINEL);
    end
endtask

function [31:0] input_payload;
    input integer frame, slot;
    integer base, lane, first, element;
    begin
        base=2+FRAME_WORDS*frame;
        input_payload=0;
        if(slot>=292) input_payload=vectors[base+slot];
        else if(slot<256) begin
            first=slot*X_LANES;
            if(X_LANES==1) input_payload=vectors[base+first];
            else for(lane=0;lane<X_LANES;lane=lane+1)
                input_payload[8*lane+:8]=vectors[base+first+lane][7:0];
        end else begin
            first=(slot-256)*W_LANES;
            if(W_LANES==1) input_payload=vectors[base+256+first];
            else begin
                for(lane=0;lane<W_LANES;lane=lane+1) begin
                    element=first+lane;
                    if(element<36) input_payload[8*lane+:8]=vectors[base+256+element][7:0];
                end
            end
        end
    end
endfunction

task load_frame;
    input integer frame;
    integer j,base;
    begin
        base=1+FRAME_WORDS*frame;
        for(j=0;j<CNN_WORDS;j=j+1)
            if(input_slot(j)>=0) sram_write(j*4,input_payload(frame,input_slot(j)));
        initialize_outputs;
        bus_write(MMIO,2); bus_write(MMIO+8,{24'b0,vectors[base][7:0]});
    end
endtask

task wait_npu;
    output [31:0] status;
    integer polls;
    begin : polling_npu
        status=1;
        for(polls=0;polls<150000;polls=polls+1) begin
            bus_read(MMIO+4,status);
            if(status[0]===1'b0) disable polling_npu;
        end
        check32("npu_watchdog",0,1);
    end
endtask

task verify_inputs;
    input integer frame;
    integer j;
    reg [31:0] actual;
    begin
        for(j=0;j<CNN_WORDS;j=j+1) if(input_slot(j)>=0) begin
            sram_read(4*j,actual);
            check32("input_word_preserved",input_payload(frame,input_slot(j)),actual);
        end
    end
endtask

task verify_frame;
    input integer frame;
    integer j,base;
    reg [31:0] actual;
    begin
        base=1+FRAME_WORDS*frame;
        verify_inputs(frame);
        for(j=0;j<2*OUT_WORDS;j=j+1) begin
            sram_read(4*RAW_BASE+4*j,actual);
            if(vectors[base][31]) check32("overflow_raw_or_quantized",vectors[base+297+j],actual);
            else check32("cnn_raw_or_quantized",vectors[base+297+j],actual);
        end
    end
endtask

task run_frame;
    input integer frame;
    reg [31:0] status;
    integer errors_before;
    begin
        errors_before=errors;
        load_frame(frame); bus_write(MMIO,1); wait_npu(status);
        check32("npu_done_without_error",2,status);
        verify_frame(frame);
        if(vectors[1+FRAME_WORDS*frame][31] && errors==errors_before)
            overflow_frames_passed=overflow_frames_passed+1;
    end
endtask

task preload_program;
    input integer count;
    integer j;
    begin
        for(j=0;j<count;j=j+1) bus_write(32'h10000+j*4,program_words[j]);
    end
endtask

task run_cpu;
    integer j;
    begin : cpu_execution
        @(negedge clk); start=1;
        @(negedge clk); start=0;
        for(j=0;j<1000000;j=j+1) begin
            @(posedge clk); #(clk_period_ps/10000.0);
            if(done===1'b1) begin
                check32("cpu_trap",0,trap);
                disable cpu_execution;
            end
        end
        check32("cpu_watchdog",0,1);
    end
endtask
