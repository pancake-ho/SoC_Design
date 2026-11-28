// Only this file connects the public contract. No checker uses DUT internals.
module dut_adapter(
    input clk,rst_n,host_valid,host_write,input [31:0] host_addr,host_wdata,
    output host_ready,output [31:0] host_rdata,output host_error,
    input start,input [31:0] boot_addr,output busy,done,trap,
    output commit_valid,output [31:0] commit_pc,commit_insn,
    output [4:0] commit_rd,output [31:0] commit_wdata,
    input [7:0] reserved_in,output [7:0] reserved_out,
    input [7:0] rp_aux_in0,rp_aux_in1,rp_aux_in2,rp_aux_in3,rp_aux_in4,rp_aux_in5,rp_aux_in6,
    output [7:0] rp_aux_out0,rp_aux_out1,rp_aux_out2,rp_aux_out3,rp_aux_out4,rp_aux_out5,rp_aux_out6
);
    project_top dut(.*);
endmodule
