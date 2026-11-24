// EE470 v9.3 NPU experiment using IDEC's tiled Winograd and shift-add ideas.
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
    localparam IDLE=4'd0, BIAS_REQ=4'd1, BIAS_WAIT=4'd2,
        FILTER_REQ=4'd3, FILTER_WAIT=4'd4, FILTER_TRANSFORM=4'd5,
        TILE_REQ=4'd6, TILE_WAIT=4'd7, TILE_START=4'd8, TILE_CALC=4'd9,
        OUTPUT_PREP=4'd10, RAW_REQ=4'd11, RAW_WAIT=4'd12, Q_REQ=4'd13, Q_WAIT=4'd14;
    localparam [10:0] X_BASE=`EE470_XQ_WORD, W_BASE=`EE470_WQ_WORD,
        BIAS_BASE=`EE470_BIAS_WORD, RAW_BASE=11'd384, Q_BASE=11'd1168;
    localparam [17:0] LAST_CYCLE=`EE470_NPU_TIMEOUT-1;
    reg [3:0] state;
    reg [17:0] elapsed;
    reg [4:0] access_wait;
    reg [7:0] saved_config;
    reg [1:0] filter_index, output_slot;
    reg [3:0] filter_slot, input_slot;
    reg [2:0] tile_row, tile_col;
    reg [9:0] filter_output_base;
    reg signed [31:0] bias;
    reg [71:0] filter_values;
    reg [127:0] input_tile;
    reg [31:0] raw_result;

    wire [3:0] input_row = {tile_row,1'b0} + {2'b00,input_slot[3:2]};
    wire [3:0] input_col = {tile_col,1'b0} + {2'b00,input_slot[1:0]};
    wire [3:0] output_row = {tile_row,output_slot[1]};
    wire [3:0] output_col = {tile_col,output_slot[0]};
    wire [10:0] filter_word = W_BASE + filter_index*11'd9 + {7'b0,filter_slot};
    wire [10:0] output_index = {1'b0,filter_output_base} + output_row*11'd14 + {7'b0,output_col};
    wire awaiting_response = state==BIAS_WAIT || state==FILTER_WAIT ||
                             state==TILE_WAIT || state==RAW_WAIT || state==Q_WAIT;

    wire tile_valid;
    wire [75:0] tile_sums;
    wire signed [18:0] selected_sum = tile_sums[output_slot*19+:19];
    wire signed [32:0] bias_extended = {bias[31],bias};
    wire signed [32:0] sum_extended = {{14{selected_sum[18]}},selected_sum};
    wire signed [32:0] biased_sum = bias_extended + sum_extended;
    wire raw_overflow = biased_sum[32] != biased_sum[31];

    assign busy = state != IDLE;
    winograd_tile_engine tile_engine(
        .clk(clk), .reset(reset || !busy), .load_filter(state==FILTER_TRANSFORM),
        .start_tile(state==TILE_START), .filter_values(filter_values), .input_tile(input_tile),
        .result_valid(tile_valid), .tile_sums(tile_sums)
    );

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
        req_valid = 0;
        req_write = 0;
        req_addr = 0;
        req_wdata = 0;
        case (state)
            BIAS_REQ: begin
                req_valid = 1;
                req_addr = BIAS_BASE + {9'b0,filter_index};
            end
            FILTER_REQ: begin
                req_valid = 1;
                req_addr = filter_word;
            end
            TILE_REQ: begin
                req_valid = 1;
                req_addr = X_BASE + {3'b0,input_row,input_col};
            end
            RAW_REQ: begin
                req_valid = 1;
                req_write = 1;
                req_addr = RAW_BASE + output_index;
                req_wdata = raw_result;
            end
            Q_REQ: begin
                req_valid = 1;
                req_write = 1;
                req_addr = Q_BASE + output_index;
                req_wdata = requantize(raw_result,saved_config);
            end
            default: begin end
        endcase
    end

    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            done <= 0;
            error <= 0;
            elapsed <= 0;
            access_wait <= 0;
            saved_config <= 0;
            filter_index <= 0;
            filter_output_base <= 0;
            filter_slot <= 0;
            input_slot <= 0;
            output_slot <= 0;
            tile_row <= 0;
            tile_col <= 0;
        end else if (!busy) begin
            if (clear) begin
                done <= 0;
                error <= 0;
            end
            if (start) begin
                state <= BIAS_REQ;
                done <= 0;
                error <= 0;
                elapsed <= 0;
                access_wait <= 0;
                saved_config <= config_value;
                filter_index <= 0;
                filter_output_base <= 0;
                filter_slot <= 0;
                tile_row <= 0;
                tile_col <= 0;
            end
        end else begin
            elapsed <= elapsed + 1'b1;
            if ((req_valid && !req_ready) || (awaiting_response && !rsp_valid))
                access_wait <= access_wait + 1'b1;
            else access_wait <= 0;

            if (elapsed==LAST_CYCLE || access_wait==5'd31 || (rsp_valid && rsp_error)) begin
                state <= IDLE;
                done <= 0;
                error <= 1;
            end else case (state)
                BIAS_REQ: if (req_ready) state <= BIAS_WAIT;
                BIAS_WAIT: if (rsp_valid) begin
                    bias <= rsp_rdata;
                    filter_slot <= 0;
                    state <= FILTER_REQ;
                end
                FILTER_REQ: if (req_ready) state <= FILTER_WAIT;
                FILTER_WAIT: if (rsp_valid) begin
                    filter_values[filter_slot*8+:8] <= rsp_rdata[7:0];
                    if (filter_slot==4'd8) state <= FILTER_TRANSFORM;
                    else begin
                        filter_slot <= filter_slot + 1'b1;
                        state <= FILTER_REQ;
                    end
                end
                FILTER_TRANSFORM: begin
                    input_slot <= 0;
                    state <= TILE_REQ;
                end
                TILE_REQ: if (req_ready) state <= TILE_WAIT;
                TILE_WAIT: if (rsp_valid) begin
                    input_tile[input_slot*8+:8] <= rsp_rdata[7:0];
                    if (input_slot==4'd15) state <= TILE_START;
                    else begin
                        input_slot <= input_slot + 1'b1;
                        state <= TILE_REQ;
                    end
                end
                TILE_START: state <= TILE_CALC;
                TILE_CALC: if (tile_valid) begin
                    output_slot <= 0;
                    state <= OUTPUT_PREP;
                end
                OUTPUT_PREP: begin
                    if (saved_config[1] && raw_overflow)
                        raw_result <= biased_sum[32] ? 32'h80000000 : 32'h7fffffff;
                    else raw_result <= biased_sum[31:0];
                    state <= RAW_REQ;
                end
                RAW_REQ: if (req_ready) state <= RAW_WAIT;
                RAW_WAIT: if (rsp_valid) state <= Q_REQ;
                Q_REQ: if (req_ready) state <= Q_WAIT;
                Q_WAIT: if (rsp_valid) begin
                    if (output_slot!=2'd3) begin
                        output_slot <= output_slot + 1'b1;
                        state <= OUTPUT_PREP;
                    end else if (tile_row==3'd6 && tile_col==3'd6) begin
                        if (filter_index==2'd3) begin
                            state <= IDLE;
                            done <= 1;
                        end else begin
                            filter_index <= filter_index + 1'b1;
                            filter_output_base <= filter_output_base + 10'd196;
                            tile_row <= 0;
                            tile_col <= 0;
                            state <= BIAS_REQ;
                        end
                    end else begin
                        if (tile_col==3'd6) begin
                            tile_col <= 0;
                            tile_row <= tile_row + 1'b1;
                        end else tile_col <= tile_col + 1'b1;
                        input_slot <= 0;
                        state <= TILE_REQ;
                    end
                end
                default: begin
                    state <= IDLE;
                    done <= 0;
                    error <= 1;
                end
            endcase
        end
    end
endmodule

