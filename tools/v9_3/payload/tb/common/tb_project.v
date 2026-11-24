`timescale 1ns/1ps
`ifndef EE470_XQ_LANES
`define EE470_XQ_LANES 1
`endif
`ifndef EE470_WQ_LANES
`define EE470_WQ_LANES 1
`endif
`ifndef EE470_XQ_WORD
`define EE470_XQ_WORD 0
`endif
`ifndef EE470_WQ_WORD
`define EE470_WQ_WORD 256
`endif
`ifndef EE470_BIAS_WORD
`define EE470_BIAS_WORD 292
`endif
module tb_project;
    localparam MMIO=`SOC_MMIO_BASE, SENTINEL=32'ha5c35a7e;
    localparam X_LANES=`EE470_XQ_LANES, W_LANES=`EE470_WQ_LANES;
    localparam X_WORDS=256, W_WORDS=36, BIAS_WORDS=4, OUT_WORDS=784;
    localparam FRAME_WORDS=1865, RAW_BASE=384, Y_BASE=1168, CNN_WORDS=2048;
    localparam [10:0] X_BASE=`EE470_XQ_WORD, W_BASE=`EE470_WQ_WORD, BIAS_BASE=`EE470_BIAS_WORD;
    reg clk=0,rst_n=0,host_valid=0,host_write=0,start=0;
    reg [31:0] host_addr=0,host_wdata=0,boot_addr=0;
    reg [7:0] reserved_in=0;
    wire host_ready,host_error,busy,done,trap,commit_valid;
    wire [31:0] host_rdata,commit_pc,commit_insn,commit_wdata;
    wire [4:0] commit_rd;
    wire [7:0] reserved_out;
    wire observe_accept,observe_response,observe_npu_owner,observe_write,observe_valid,observe_ready;
    wire [10:0] observe_address;
    wire [31:0] observe_wdata;
    dut_adapter adapter(.*);
    `ifndef EE470_CLK_PERIOD_PS
    `define EE470_CLK_PERIOD_PS 10000
    `endif
    `ifndef EE470_CLK_LATENCY_PS
    `define EE470_CLK_LATENCY_PS 0
    `endif
    localparam integer clk_period_ps=`EE470_CLK_PERIOD_PS;
    localparam integer clk_latency_ps=`EE470_CLK_LATENCY_PS;
    initial begin
        if(clk_period_ps<20 || clk_period_ps>1000000 || clk_period_ps%2 ||
           clk_latency_ps<0 || clk_latency_ps>1000000)
            $fatal(1,"Invalid clock period or latency in ps");
        #(clk_latency_ps/1000.0);
        forever #(clk_period_ps/2000.0) clk=~clk;
    end

    integer checks=0,errors=0,cycle_count=0,protocol_errors=0;
    integer overflow_frames_passed=0;
    integer last_cnn_cycles=0,cnn_start_cycle=0,cpu_start_pc=0,cpu_start_stores=0;
    integer cpu_start_cycle=0,cpu_cycles=0,cpu_npu_starts=0;
    integer trace_index=0,program_count=0,dummy,waves=0,power_capture=0;
    reg trace_enabled=0,previous_npu_done=0,previous_npu_busy=0;
    integer cnn_reads=0,last_cnn_reads=0,cnn_writes=0,last_cnn_writes=0;
    reg memory_outstanding=0,outstanding_npu=0,request_stalled=0;
    reg [43:0] held_request=0;
    reg [8*48-1:0] first_failure=0;
    reg [8*16-1:0] case_name;
    reg [8*4096-1:0] vector_path,program_path,trace_path;
    reg [31:0] vectors[0:186500],program_words[0:255],trace_words[0:2047];
    reg u_valid=0,u_write=0,u_reset=1;
    reg [5:0] u_addr=0;
    reg [31:0] u_data=0;
    reg [3:0] u_delay=0;
    wire u_ready,u_rsp,u_error;
    wire [31:0] u_rdata;
`ifndef EE470_GATE_LEVEL
    sram_wrapper unit_memory(.clk(clk),.reset(u_reset),.req_valid(u_valid),.req_write(u_write),
        .req_addr(u_addr),.req_wdata(u_data),.req_ready(u_ready),.rsp_valid(u_rsp),
        .rsp_error(u_error),.rsp_rdata(u_rdata),.fault_delay(u_delay),.fault_error(1'b0),
        .fault_drop(1'b0),.fault_stall(1'b0));
`endif
    `include "npu_checkpoint.vh"
    `include "checker.vh"
    `include "driver.vh"
    `include "unit_wrapper.vh"
    `include "monitor.vh"
    `include "public_cases.vh"
    `include "student_cases.vh"
    initial begin
        if(checkpoint_injected_ps<0 || checkpoint_injected_ps>=clk_period_ps)
            $fatal(1,"Invalid checkpoint demonstration delay in ps");
`ifdef EE470_GATE_LEVEL
        if(checkpoint_injected_ps!=0) $fatal(1,"Gate timing must measure SDF pin delays");
`endif
        if(!$value$plusargs("CASE=%s",case_name)) $fatal(1,"CASE required");
        if(!$value$plusargs("VECTORS=%s",vector_path)) $fatal(1,"VECTORS required");
        dummy=$value$plusargs("WAVES=%d",waves);
        dummy=$value$plusargs("POWER=%d",power_capture);
        if(power_capture) begin
            // Power scope excludes the testbench and the adapter's observation logic.
            $dumpfile("activity.vcd"); $dumpvars(0,tb_project.adapter.dut);
        end else if(waves) begin $dumpfile("activity.vcd"); $dumpvars(0,tb_project); end
        $readmemh(vector_path,vectors);
        if(case_name=="F01" || case_name=="F12") begin
            dummy=$value$plusargs("PROGRAM=%s",program_path);
            dummy=$value$plusargs("PROGRAM_WORDS=%d",program_count);
            $readmemh(program_path,program_words,0,program_count-1);
            if(case_name=="F01") begin
                dummy=$value$plusargs("TRACE=%s",trace_path); $readmemh(trace_path,trace_words);
            end
            dummy=$value$plusargs("START_PC=%d",cpu_start_pc);
        end
        reset_dut; u_reset=0;
        if(case_name=="S01") run_student_cases;
        else run_public_case;
        finish_case;
    end
endmodule
