`timescale 1ps/1ps
// Track Conv2 progress and accumulate, quantize, and pool two input channels.
module conv2_accumulate_pool (
    input logic clk, rst_n,
    input logic issue_c2,
    input logic req_valid, req_is_fc,
    input logic [0:23] b_2,
    input logic [8:0] c1_commit_count,
    input logic rsp_valid, rsp_is_fc,
    input logic [15:0] rsp_tag,
    input logic signed [19:0] rsp_y00, rsp_y01, rsp_y10, rsp_y11,
    output logic c2_data_ready,
    output logic [1:0] c2_issue_pr, c2_issue_pc, c2_issue_oc,
    output logic c2_issue_ic,
    output logic [2:0] c2_base_slot,
    output logic [7:0] fmap2 [0:2][0:3][0:3],
    output logic last_c2_commit
);
    import cnn_core_pkg::*;

    logic [7:0] c2_issue_count;
    logic signed [19:0] c2_acc00, c2_acc01, c2_acc10, c2_acc11;

    // Separate channel accumulation, quantization, and max-pool/ReLU writeback.
    logic c2_wb0_valid, c2_wb1_valid;
    logic [1:0] c2_wb0_pr, c2_wb0_pc, c2_wb0_oc;
    logic [1:0] c2_wb1_pr, c2_wb1_pc, c2_wb1_oc;
    logic signed [19:0] c2_wb0_sum00, c2_wb0_sum01, c2_wb0_sum10, c2_wb0_sum11;
    logic signed [11:0] c2_wb1_q00, c2_wb1_q01, c2_wb1_q10, c2_wb1_q11;
    logic [5:0] c2_commit_count;
    localparam integer C2_RESTORE_SHIFT = 4; // generated from selected configuration

    function automatic logic signed [7:0] get_b2(input integer oc);
        begin
            case (oc)
                0: get_b2 = $signed(b_2[0+:8]);
                1: get_b2 = $signed(b_2[8+:8]);
                2: get_b2 = $signed(b_2[16+:8]);
                default: get_b2 = 8'sd0;
            endcase
        end
    endfunction

    function automatic logic signed [11:0] conv2_q(
        input logic signed [19:0] sum20,
        input logic signed [7:0] bias8
    );
        logic signed [13:0] t14;
        logic signed [12:0] pre13;
        logic signed [11:0] b12;
        logic signed [13:0] add14;
        begin
            t14   = sum20[19:6];
            pre13 = $signed(t14[13:1]);
            b12   = {{4{bias8[7]}},bias8};
            add14 = $signed(pre13) + $signed(b12);
            conv2_q = add14[11:0];
        end
    endfunction

    wire rsp_layer = rsp_tag[15];
    wire [3:0] rsp_pr = rsp_tag[11:8];
    wire [3:0] rsp_pc = rsp_tag[7:4];
    wire [1:0] rsp_oc = rsp_tag[3:2];
    wire [1:0] rsp_ic = rsp_tag[1:0];
    logic signed [19:0] rsp_eng20_00, rsp_eng20_01, rsp_eng20_10, rsp_eng20_11;
    logic signed [11:0] c2_wb0_q00, c2_wb0_q01, c2_wb0_q10, c2_wb0_q11;
    integer c2_required_commit_idx;

    always_comb begin
        // fmap1 is produced row-major, col-major, then two physical channels.
        // Physical ic0/ic1 map to original Conv1 channels 1/2.
        c2_required_commit_idx = (((c2_issue_pr*2 + 5) * 12
                                 + (c2_issue_pc*2 + 5)) * 2
                                 + c2_issue_ic);
        c2_data_ready = (c2_issue_count < 8'd96)
                     && (c1_commit_count > c2_required_commit_idx);
    end

    always_comb begin
        rsp_eng20_00 = $signed(rsp_y00[19:0]) <<< C2_RESTORE_SHIFT;
        rsp_eng20_01 = $signed(rsp_y01[19:0]) <<< C2_RESTORE_SHIFT;
        rsp_eng20_10 = $signed(rsp_y10[19:0]) <<< C2_RESTORE_SHIFT;
        rsp_eng20_11 = $signed(rsp_y11[19:0]) <<< C2_RESTORE_SHIFT;

        // WB1 quantization is now isolated from engine-output accumulation.
        c2_wb0_q00 = conv2_q(c2_wb0_sum00,get_b2(c2_wb0_oc));
        c2_wb0_q01 = conv2_q(c2_wb0_sum01,get_b2(c2_wb0_oc));
        c2_wb0_q10 = conv2_q(c2_wb0_sum10,get_b2(c2_wb0_oc));
        c2_wb0_q11 = conv2_q(c2_wb0_sum11,get_b2(c2_wb0_oc));
    end

    assign last_c2_commit = c2_wb1_valid && (c2_commit_count == 6'd47);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            c2_issue_pr <= 0; c2_issue_pc <= 0;
            c2_issue_oc <= 0; c2_issue_ic <= 0;
            c2_base_slot <= 0;
            c2_issue_count <= 0;
            c2_acc00 <= 0; c2_acc01 <= 0; c2_acc10 <= 0; c2_acc11 <= 0;

            c2_wb0_valid <= 1'b0;
            c2_wb1_valid <= 1'b0;
            c2_wb0_pr <= 0; c2_wb0_pc <= 0; c2_wb0_oc <= 0;
            c2_wb1_pr <= 0; c2_wb1_pc <= 0; c2_wb1_oc <= 0;
            c2_wb0_sum00 <= 0; c2_wb0_sum01 <= 0;
            c2_wb0_sum10 <= 0; c2_wb0_sum11 <= 0;
            c2_wb1_q00 <= 0; c2_wb1_q01 <= 0;
            c2_wb1_q10 <= 0; c2_wb1_q11 <= 0;
            c2_commit_count <= 0;
        end else begin
            // Conv2 writeback pipeline advances every cycle.
            c2_wb0_valid <= 1'b0;
            c2_wb1_valid <= c2_wb0_valid;
            if (c2_wb0_valid) begin
                c2_wb1_pr <= c2_wb0_pr;
                c2_wb1_pc <= c2_wb0_pc;
                c2_wb1_oc <= c2_wb0_oc;
                c2_wb1_q00 <= c2_wb0_q00;
                c2_wb1_q01 <= c2_wb0_q01;
                c2_wb1_q10 <= c2_wb0_q10;
                c2_wb1_q11 <= c2_wb0_q11;
            end

            // Commit pooled Conv2 output from the isolated WB1 stage.
            if (c2_wb1_valid) begin
                fmap2[c2_wb1_oc][c2_wb1_pr][c2_wb1_pc] <=
                    max4_relu_a8(c2_wb1_q00,c2_wb1_q01,c2_wb1_q10,c2_wb1_q11);
                c2_commit_count <= c2_commit_count + 1'b1;
            end

            if (req_valid && !req_is_fc && issue_c2) begin
                c2_issue_count <= c2_issue_count + 1'b1;
                if (c2_issue_ic == 1'b0) begin
                    c2_issue_ic <= 1'b1;
                end else begin
                    c2_issue_ic <= 1'b0;
                    if (c2_issue_oc < 2) begin
                        c2_issue_oc <= c2_issue_oc + 1'b1;
                    end else begin
                        c2_issue_oc <= 0;
                        if (c2_issue_pc < 3) begin
                            c2_issue_pc <= c2_issue_pc + 1'b1;
                        end else begin
                            c2_issue_pc <= 0;
                            if (c2_issue_pr < 3) begin
                                c2_issue_pr <= c2_issue_pr + 1'b1;
                                c2_base_slot <= add_mod7(c2_base_slot,2);
                            end
                        end
                    end
                end
            end

            // Conv2 response -> two-input-channel accumulation.
            // The second input-channel result is captured into WB0 instead of running
            // accumulation + quantization + pool/ReLU in one cycle.
            if (rsp_valid && !rsp_is_fc && (rsp_layer == 1'b1)) begin
                if (rsp_ic == 0) begin
                    c2_acc00 <= rsp_eng20_00;
                    c2_acc01 <= rsp_eng20_01;
                    c2_acc10 <= rsp_eng20_10;
                    c2_acc11 <= rsp_eng20_11;
                end else begin
                    c2_wb0_valid <= 1'b1;
                    c2_wb0_pr <= rsp_pr[1:0];
                    c2_wb0_pc <= rsp_pc[1:0];
                    c2_wb0_oc <= rsp_oc;
                    c2_wb0_sum00 <= c2_acc00 + rsp_eng20_00;
                    c2_wb0_sum01 <= c2_acc01 + rsp_eng20_01;
                    c2_wb0_sum10 <= c2_acc10 + rsp_eng20_10;
                    c2_wb0_sum11 <= c2_acc11 + rsp_eng20_11;

                    c2_acc00 <= 0; c2_acc01 <= 0;
                    c2_acc10 <= 0; c2_acc11 <= 0;
                end
            end
        end
    end
endmodule
