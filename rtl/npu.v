// EE470 functional slow baseline: eight-cycle serial multiply, no data/filter cache.
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
`ifndef EE470_NPU_TIMEOUT
`define EE470_NPU_TIMEOUT 262144
`endif
module npu(
    input clk, reset, start, clear, input [7:0] config_value,
    output busy, output reg done, error,
    output reg req_valid, req_write, output reg [10:0] req_addr,
    output reg [31:0] req_wdata, input req_ready, rsp_valid, rsp_error,
    input [31:0] rsp_rdata
);
    localparam IDLE=0, BIAS_REQ=1, BIAS_WAIT=2, X_REQ=3, X_WAIT=4,
        W_REQ=5, W_WAIT=6, RAW_REQ=7, RAW_WAIT=8, Q_REQ=9, Q_WAIT=10, MUL=11;
    reg [3:0] state;
    reg [1:0] filter_index;
    reg [3:0] output_row, output_col;
    reg [9:0] output_index;
    reg [3:0] kernel_index;
    reg [17:0] elapsed;
    reg [5:0] access_wait;
    reg [7:0] saved_config;
    reg signed [7:0] x_value;
    // signed32 bias plus nine signed16 products always fits signed33.
    reg signed [32:0] accumulator;
    reg [31:0] raw_result;
    reg [7:0] multiplier_bits;
    reg [15:0] multiplicand, partial_product;
    reg [2:0] bit_index;
    reg product_negative;
    localparam X_LANES=`EE470_XQ_LANES, W_LANES=`EE470_WQ_LANES;
    wire [7:0] x_index = (output_row+kernel_index/3)*16 + output_col+kernel_index%3;
    wire [7:0] x_byte = rsp_rdata[(x_index % X_LANES)*8+:8];
    wire [7:0] w_byte = rsp_rdata[(kernel_index % W_LANES)*8+:8];
    wire [7:0] x_magnitude = x_value[7] ? (~x_value + 8'd1) : x_value;
    wire [7:0] w_magnitude = w_byte[7] ? (~w_byte + 8'd1) : w_byte;
    wire [15:0] next_product = partial_product + (multiplier_bits[0] ? multiplicand : 16'b0);
    wire [15:0] signed_product = product_negative ? (~next_product + 16'd1) : next_product;
    wire signed [32:0] extended_product = {{17{signed_product[15]}},signed_product};
    wire signed [32:0] next_accumulator = accumulator + extended_product;
    wire [31:0] narrowed_result = saved_config[1] && next_accumulator[32]!=next_accumulator[31] ?
        (next_accumulator[32] ? 32'h80000000 : 32'h7fffffff) : next_accumulator[31:0];
    assign busy = state != IDLE;

    function [31:0] requantize;
        input signed [31:0] value;
        input [7:0] cfg;
        reg signed [32:0] a;
        reg [32:0] magnitude, rounded;
        reg signed [33:0] signed_result;
        begin
            a = {value[31],value};
            if (cfg[0] && a < 0) a = 0;
            magnitude = a < 0 ? -a : a;
            rounded = cfg[7:4] == 0 ? magnitude :
                (magnitude + (33'd1 << (cfg[7:4]-1))) >> cfg[7:4];
            signed_result = a < 0 ? -$signed({1'b0,rounded}) : $signed({1'b0,rounded});
            if (signed_result > 127) requantize = 32'h0000007f;
            else if (signed_result < -128) requantize = 32'h00000080;
            else requantize = {24'b0,signed_result[7:0]};
        end
    endfunction

    always @* begin
        req_valid = 0; req_write = 0; req_addr = 0; req_wdata = 0;
        case (state)
            BIAS_REQ: begin req_valid=1; req_addr=`EE470_BIAS_WORD+filter_index; end
            X_REQ: begin
                req_valid=1;
                req_addr=`EE470_XQ_WORD+x_index/X_LANES;
            end
            W_REQ: begin req_valid=1; req_addr=`EE470_WQ_WORD+filter_index*9+kernel_index/W_LANES; end
            RAW_REQ: begin req_valid=1; req_write=1; req_addr=384+output_index; req_wdata=raw_result; end
            Q_REQ: begin req_valid=1; req_write=1; req_addr=1168+output_index;
                req_wdata=requantize(raw_result,saved_config); end
            default: begin end
        endcase
    end
    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (reset) begin
            state<=IDLE; done<=0; error<=0; elapsed<=0; access_wait<=0;
            filter_index<=0; output_row<=0; output_col<=0; raw_result<=0;
            output_index<=0; kernel_index<=0; accumulator<=0; x_value<=0; saved_config<=0;
            multiplier_bits<=0; multiplicand<=0; partial_product<=0; bit_index<=0; product_negative<=0;
        end else begin
            if (clear && !busy) begin done<=0; error<=0; end
            if (start && !busy) begin
                state<=BIAS_REQ; done<=0; error<=0; elapsed<=0; access_wait<=0;
                filter_index<=0; output_row<=0; output_col<=0;
                output_index<=0; kernel_index<=0; saved_config<=config_value;
            end else if (busy) begin
                elapsed<=elapsed+1'b1;
                if (state==MUL || rsp_valid || (req_valid && req_ready)) access_wait<=0;
                else access_wait<=access_wait+1'b1;
                if (elapsed>=`EE470_NPU_TIMEOUT-1 || access_wait==31 || (rsp_valid && rsp_error)) begin
                    state<=IDLE; error<=1; done<=0;
                end else case(state)
                    BIAS_REQ: if(req_ready) state<=BIAS_WAIT;
                    BIAS_WAIT: if(rsp_valid) begin
                        accumulator<={rsp_rdata[31],rsp_rdata}; kernel_index<=0; state<=X_REQ;
                    end
                    X_REQ: if(req_ready) state<=X_WAIT;
                    X_WAIT: if(rsp_valid) begin x_value<=x_byte; state<=W_REQ; end
                    W_REQ: if(req_ready) state<=W_WAIT;
                    W_WAIT: if(rsp_valid) begin
                        multiplier_bits<=w_magnitude;
                        multiplicand<={8'b0,x_magnitude}; partial_product<=0;
                        product_negative<=x_value[7]^w_byte[7]; bit_index<=0; state<=MUL;
                    end
                    MUL: begin
                        partial_product<=next_product;
                        multiplier_bits<=multiplier_bits>>1;
                        multiplicand<=multiplicand<<1;
                        if(bit_index==7) begin
                            accumulator<=next_accumulator;
                            if(kernel_index!=8) begin kernel_index<=kernel_index+1'b1; state<=X_REQ; end
                            else begin
                                raw_result<=narrowed_result; state<=RAW_REQ;
                            end
                        end else bit_index<=bit_index+1'b1;
                    end
                    RAW_REQ: if(req_ready) state<=RAW_WAIT;
                    RAW_WAIT: if(rsp_valid) state<=Q_REQ;
                    Q_REQ: if(req_ready) state<=Q_WAIT;
                    Q_WAIT: if(rsp_valid) begin
                        if(output_index==783) begin state<=IDLE; done<=1; end
                        else begin
                            output_index<=output_index+1'b1; state<=BIAS_REQ;
                            if(output_col==13) begin
                                output_col<=0;
                                if(output_row==13) begin output_row<=0; filter_index<=filter_index+1'b1; end
                                else output_row<=output_row+1'b1;
                            end else output_col<=output_col+1'b1;
                        end
                    end
                    default: begin state<=IDLE; error<=1; end
                endcase
            end
        end
    end
endmodule
