module sram_wrapper #(parameter ADDR_WIDTH=6)(
    input clk, reset, req_valid, req_write,
    input [ADDR_WIDTH-1:0] req_addr, input [31:0] req_wdata,
    output req_ready, output reg rsp_valid, rsp_error,
    output reg [31:0] rsp_rdata,
    input [3:0] fault_delay, input fault_error, fault_drop, fault_stall
);
    reg pending, saved_write, saved_error, saved_drop;
    reg [4:0] wait_cycles;
    wire accept = req_valid && req_ready && !reset;
    wire [31:0] memory_q;
    assign req_ready = !reset && !pending && !rsp_valid && !fault_stall;
`ifdef USE_MACRO
    // SAED32 is clocked; address is a word index, all 512 words count as area.
    localparam BANKS = ADDR_WIDTH <= 9 ? 1 : (1 << (ADDR_WIDTH-9));
    wire [8:0] macro_addr;
    generate if (ADDR_WIDTH <= 9) begin: small_address
        assign macro_addr = {{(9-ADDR_WIDTH){1'b0}},req_addr};
    end else begin: large_address
        assign macro_addr = req_addr[8:0];
    end endgenerate
    reg [ADDR_WIDTH-1:0] saved_address;
    wire [31:0] bank_q[0:BANKS-1];
    genvar bank;
    generate for (bank=0; bank<BANKS; bank=bank+1) begin: banks
        SRAM1RW512x32 memory(.A(macro_addr), .CE(clk), .WEB(!req_write),
            .OEB(1'b0), .CSB(!(accept && (req_addr >> 9)==bank)), .I(req_wdata), .O(bank_q[bank]));
    end endgenerate
    assign memory_q = bank_q[saved_address >> 9];
    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (reset) saved_address <= 0;
        else if (accept) saved_address <= req_addr;
    end
`else
    reg [31:0] memory[0:(1<<ADDR_WIDTH)-1];
    reg [31:0] read_q;
    assign memory_q = read_q;
    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (accept) begin
            if (req_write) memory[req_addr] <= req_wdata;
            else read_q <= memory[req_addr];
        end
    end
`endif
    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (reset) begin
            pending <= 0; rsp_valid <= 0; rsp_error <= 0; rsp_rdata <= 0;
            wait_cycles <= 0; saved_write <= 0; saved_error <= 0; saved_drop <= 0;
        end else begin
            rsp_valid <= 0;
            if (accept) begin
                pending <= 1; wait_cycles <= {1'b0,fault_delay};
                saved_write <= req_write; saved_error <= fault_error; saved_drop <= fault_drop;
            end else if (pending) begin
                if (wait_cycles != 0) wait_cycles <= wait_cycles - 1'b1;
                else begin
                    pending <= 0;
                    rsp_valid <= !saved_drop;
                    rsp_error <= saved_error;
                    rsp_rdata <= saved_write ? 32'b0 : memory_q;
                end
            end
        end
    end
endmodule
