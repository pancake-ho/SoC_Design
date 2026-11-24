// Only this file connects the public contract. No checker uses DUT internals.
module dut_adapter(
    input clk,rst_n,host_valid,host_write,input [31:0] host_addr,host_wdata,
    output host_ready,output [31:0] host_rdata,output host_error,
    input start,input [31:0] boot_addr,output busy,done,trap,
    output commit_valid,output [31:0] commit_pc,commit_insn,
    output [4:0] commit_rd,output [31:0] commit_wdata,
    input [7:0] reserved_in,output [7:0] reserved_out,
    output observe_accept,observe_response,observe_npu_owner,observe_write,
    output observe_valid,observe_ready,output [10:0] observe_address,
    output [31:0] observe_wdata
);
    project_top dut(.*);
`ifdef EE470_GATE_LEVEL
    // Gate F12 uses only the frozen interface. RTL suite retains protocol tracing.
    assign {observe_accept,observe_response,observe_npu_owner,observe_write,
            observe_valid,observe_ready,observe_address,observe_wdata} = 49'b0;
`else
    // Architectural wrapper ports only. FSM/accumulator/cache names are not inspected.
    assign observe_accept=dut.u_soc.memory_req && dut.u_soc.memory_ready;
    assign observe_response=dut.u_soc.memory_valid;
    assign observe_npu_owner=dut.u_soc.npu_busy;
    assign observe_write=dut.u_soc.memory_write;
    assign observe_valid=dut.u_soc.memory_req;
    assign observe_ready=dut.u_soc.memory_ready;
    assign observe_address=dut.u_soc.memory_addr;
    assign observe_wdata=dut.u_soc.memory_wdata;
`endif
endmodule
