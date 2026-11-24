`ifndef SOC_MMIO_BASE
`define SOC_MMIO_BASE 1024
`endif
`ifndef SOC_CONST_BASE
`define SOC_CONST_BASE 1536
`endif
module soc_system(
    input clk, rst_n, host_valid, host_write, input [31:0] host_addr, host_wdata,
    output host_ready, output reg [31:0] host_rdata, output host_error,
    input start, input [31:0] boot_addr, output busy, output reg done, trap,
    output commit_valid, output [31:0] commit_pc, commit_insn,
    output [4:0] commit_rd, output [31:0] commit_wdata,
    input [7:0] reserved_in, output [7:0] reserved_out
);
    localparam MMIO=`SOC_MMIO_BASE, CONST_BASE=`SOC_CONST_BASE;
    wire reset=!rst_n;
    reg running;
    reg [31:0] constants[0:63], instruction;
    reg fetch_pending, instruction_valid, host_imem_pending, local_pending;
    reg response_is_local;
    wire [31:0] pc, alu_result, cpu_wdata;
    reg [31:0] cpu_rdata;
    wire cpu_memwrite;
    wire host_access=host_valid && !running && !reset;
    wire [31:0] bus_addr=running ? alu_result : host_addr;
    wire [31:0] bus_wdata=running ? cpu_wdata : host_wdata;
    wire aligned=bus_addr[1:0]==0;
    wire mmio_select=aligned && bus_addr>=MMIO && bus_addr<MMIO+32;
    wire [4:0] offset=bus_addr-MMIO;
    wire local_select=aligned && bus_addr<256;
    wire const_select=aligned && bus_addr>=CONST_BASE && bus_addr<CONST_BASE+256;
    wire host_imem=host_access && aligned && host_addr>=32'h10000 && host_addr<32'h10400;
    wire host_constants=host_access && aligned && host_addr>=32'h20000 && host_addr<32'h20100;
    wire host_local=host_access && local_select;
    wire valid_pc=pc[1:0]==0 && pc<1024;
    wire fetch_request=running && valid_pc && !fetch_pending && !instruction_valid;
    wire imem_request=fetch_request || (host_imem && !host_imem_pending);
    wire imem_ready, imem_valid, imem_error;
    wire [31:0] imem_rdata;
    wire cpu_local=running && instruction_valid && local_select &&
        (instruction[6:0]==7'h03 || cpu_memwrite);
    wire local_request=(cpu_local || host_local) && !local_pending;
    wire local_response, local_accept, memory_error;
    wire cpu_step=running && instruction_valid &&
        (!cpu_local || (local_pending && local_response && !memory_error));
    wire write_access=!reset && (running ? cpu_step && cpu_memwrite : host_access && host_write);
    reg [7:0] config_register;
    reg [31:0] address_register, data_register, transfer_rdata;
    reg [1:0] transfer_state;
    reg transfer_write, transfer_done, transfer_error, control_error;
    reg [4:0] transfer_elapsed;
    wire npu_busy, npu_done, npu_error;
    wire npu_start=write_access && mmio_select && offset==0 && bus_wdata[0] && !npu_busy && transfer_state==0;
    wire npu_clear=write_access && mmio_select && offset==0 && bus_wdata[1] && !npu_busy;
    wire n_valid,n_write;
    wire [10:0] n_addr;
    wire [31:0] n_wdata;
    wire memory_ready, memory_valid;
    wire [31:0] memory_rdata;
    wire memory_req=npu_busy ? n_valid : transfer_state==1;
    wire memory_write=npu_busy ? n_write : transfer_write;
    wire [10:0] memory_addr=npu_busy ? n_addr : address_register[12:2];
    wire [31:0] memory_wdata=npu_busy ? n_wdata : data_register;
    wire dmem_ready, dmem_valid;
    // One logical DMEM port. Four 512x32 banks. CPU-local words 320..383 are reserved.
    wire dmem_request=memory_req || local_request;
    assign memory_ready=dmem_ready;
    assign memory_valid=dmem_valid && !response_is_local;
    assign local_response=dmem_valid && response_is_local;
    assign local_accept=dmem_ready && local_request && !memory_req;
    assign host_ready=host_access &&
        (host_imem ? host_imem_pending && imem_valid :
         host_local ? local_pending && local_response : 1'b1);
    assign host_error=host_ready &&
        (host_imem ? imem_error : host_local ? memory_error :
         !(mmio_select || const_select || host_constants));
    assign busy=running;
    assign reserved_out={4'b0,transfer_error,control_error|npu_error,npu_done,npu_busy};
    RISCVsingle cpu(.clk(clk),.reset(reset || !running),.step_en(cpu_step),.PC(pc),.Instr(instruction),
        .MemWrite(cpu_memwrite),.ALUResult(alu_result),.WriteData(cpu_wdata),.ReadData(cpu_rdata));
    assign commit_valid=cpu_step && !reset;
    assign commit_pc=pc;
    assign commit_insn=instruction;
    wire writes_rd=instruction[6:0]==7'h33 || instruction[6:0]==7'h13 ||
        instruction[6:0]==7'h03 || instruction[6:0]==7'h6f;
    assign commit_rd=writes_rd ? instruction[11:7] : 5'b0;
    assign commit_wdata=commit_rd==0 ? 32'b0 : instruction[6:0]==7'h03 ? cpu_rdata :
        instruction[6:0]==7'h6f ? pc+4 : alu_result;

    npu accelerator(.clk(clk),.reset(reset),.start(npu_start),.clear(npu_clear),
        .config_value(config_register),.busy(npu_busy),.done(npu_done),.error(npu_error),
        .req_valid(n_valid),.req_write(n_write),.req_addr(n_addr),.req_wdata(n_wdata),
        .req_ready(memory_ready && npu_busy),.rsp_valid(memory_valid && npu_busy),
        .rsp_error(memory_error),.rsp_rdata(memory_rdata));
    sram_wrapper #(.ADDR_WIDTH(8)) imem_port(
        .clk(clk),.reset(reset),.req_valid(imem_request),.req_write(host_imem && host_write),
        .req_addr(running ? pc[9:2] : host_addr[9:2]),.req_wdata(host_wdata),
        .req_ready(imem_ready),.rsp_valid(imem_valid),.rsp_error(imem_error),.rsp_rdata(imem_rdata),
        .fault_delay(4'b0),.fault_error(1'b0),.fault_drop(1'b0),.fault_stall(1'b0));

    sram_wrapper #(.ADDR_WIDTH(11)) memory_port(
        .clk(clk),.reset(reset),.req_valid(dmem_request),
        .req_write(memory_req ? memory_write : running ? cpu_memwrite : host_write),
        .req_addr(memory_req ? memory_addr : 11'd320+{5'b0,bus_addr[7:2]}),
        .req_wdata(memory_req ? memory_wdata : bus_wdata),.req_ready(dmem_ready),
        .rsp_valid(dmem_valid),.rsp_error(memory_error),.rsp_rdata(memory_rdata),
        .fault_delay(memory_req ? reserved_in[3:0] : 4'b0),.fault_error(memory_req && reserved_in[4]),
        .fault_drop(memory_req && reserved_in[5]),.fault_stall(memory_req && reserved_in[6]));

    always @* begin
        cpu_rdata=0;
        if(local_select) cpu_rdata=memory_rdata;
        else if(const_select) cpu_rdata=constants[(bus_addr-CONST_BASE)>>2];
        else if(mmio_select) case(offset)
            4: cpu_rdata={29'b0,control_error|npu_error,npu_done,npu_busy};
            8: cpu_rdata={24'b0,config_register};
            12: cpu_rdata=address_register;
            16: cpu_rdata=data_register;
            24: cpu_rdata={29'b0,transfer_error,transfer_done,transfer_state!=0};
            28: cpu_rdata=transfer_rdata;
            default: cpu_rdata=0;
        endcase
        host_rdata=cpu_rdata;
        if(host_imem) host_rdata=imem_rdata;
        if(host_constants)
            host_rdata=constants[host_addr[7:2]];
    end

    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if(reset) begin
            running<=0; done<=0; trap<=0; config_register<=8'h23;
            fetch_pending<=0; instruction_valid<=0; instruction<=0;
            host_imem_pending<=0; local_pending<=0; response_is_local<=0;
            address_register<=0; data_register<=0; transfer_state<=0;
            transfer_done<=0; transfer_error<=0; transfer_rdata<=0;
            transfer_write<=0; transfer_elapsed<=0; control_error<=0;
        end else begin
            if(start && !running && !host_valid && !host_imem_pending && !local_pending) begin
                done<=0; trap<=boot_addr!=0; running<=boot_addr==0;
            end
            if(imem_request && imem_ready) begin
                if(running) fetch_pending<=1;
                else host_imem_pending<=1;
            end
            if(host_imem_pending && imem_valid) host_imem_pending<=0;
            if(fetch_pending && imem_valid) begin
                fetch_pending<=0; instruction_valid<=!imem_error; instruction<=imem_rdata;
            end
            if(dmem_request && dmem_ready) response_is_local<=!memory_req;
            if(local_accept) local_pending<=1;
            if(local_response) local_pending<=0;
            if(cpu_step) begin
                instruction_valid<=0;
                if(cpu_memwrite && local_select && bus_addr==32'hf0) begin running<=0; done<=1; end
            end
            if(running && (!valid_pc || (fetch_pending && imem_valid && imem_error) ||
                           (cpu_local && local_response && memory_error))) begin
                running<=0; trap<=1; done<=1; instruction_valid<=0;
            end
            if(host_constants && host_write) constants[host_addr[7:2]]<=host_wdata;
            if(transfer_state!=0) begin
                transfer_elapsed<=transfer_elapsed+1'b1;
                if(transfer_elapsed>=15) begin transfer_state<=0; transfer_done<=0; transfer_error<=1; end
                else if(transfer_state==1 && memory_ready) transfer_state<=2;
                else if(transfer_state==2 && memory_valid) begin
                    transfer_state<=0; transfer_error<=transfer_error|memory_error; transfer_done<=!memory_error;
                    if(!memory_error && !transfer_write) transfer_rdata<=memory_rdata;
                end
            end
            if(write_access && mmio_select) case(offset)
                0: begin
                    if(npu_clear) control_error<=0;
                    if(bus_wdata[0]) begin
                        if(npu_busy || transfer_state!=0) control_error<=1;
                        else control_error<=0;
                    end
                end
                8: if(npu_busy) control_error<=1;
                   else config_register<=bus_wdata[7:0]&8'hf3;
                12: if(transfer_state!=0) transfer_error<=1; else address_register<=bus_wdata;
                16: if(transfer_state!=0) transfer_error<=1; else data_register<=bus_wdata;
                20: begin
                    if(transfer_state==0) begin
                        if(bus_wdata[2]) begin transfer_done<=0; transfer_error<=0; end
                        if(bus_wdata[1:0]!=0) begin
                            if(npu_busy || bus_wdata[1:0]==3 || address_register[1:0]!=0 || address_register>8191 || (address_register>=1280 && address_register<1536)) begin
                                transfer_error<=1;
                            end else begin
                                transfer_state<=1; transfer_write<=bus_wdata[1]; transfer_elapsed<=0;
                                transfer_done<=0; transfer_error<=0;
                            end
                        end
                    end else if(bus_wdata[1:0]!=0) transfer_error<=1;
                end
                default: begin end
            endcase
        end
    end
endmodule
