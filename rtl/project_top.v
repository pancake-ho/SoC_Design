// Frozen assessment boundary. All implementation changes belong in student/rtl.
module project_top (
    input wire clk, input wire rst_n,
    input wire host_valid, input wire host_write,
    input wire [31:0] host_addr, input wire [31:0] host_wdata,
    output wire host_ready, output wire [31:0] host_rdata, output wire host_error,
    input wire start, input wire [31:0] boot_addr,
    output wire busy, output wire done, output wire trap,
    output wire commit_valid, output wire [31:0] commit_pc,
    output wire [31:0] commit_insn, output wire [4:0] commit_rd,
    output wire [31:0] commit_wdata,
    input wire [7:0] reserved_in, output wire [7:0] reserved_out
);
    soc_system u_soc (
        .clk(clk), .rst_n(rst_n),
        .host_valid(host_valid), .host_write(host_write),
        .host_addr(host_addr), .host_wdata(host_wdata),
        .host_ready(host_ready), .host_rdata(host_rdata), .host_error(host_error),
        .start(start), .boot_addr(boot_addr), .busy(busy), .done(done), .trap(trap),
        .commit_valid(commit_valid), .commit_pc(commit_pc), .commit_insn(commit_insn),
        .commit_rd(commit_rd), .commit_wdata(commit_wdata),
        .reserved_in(reserved_in), .reserved_out(reserved_out)
    );
endmodule
