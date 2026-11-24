// =============================================================================
// Controller for the multiplierless fixed-model PFDW CNN accelerator.
//
// Search point: W477_A88_Cpot1-pot1-sp2_T32-0-0_M67
//   * Conv1: original output channel 0 removed; original channels 1/2 kept.
//   * Conv2: all three output channels kept, but only the two surviving Conv1
//            channels are consumed.
//   * Conv1/Conv2 transformed coefficients use up to two signed powers of two.
//   * FC SP2 coefficients are evaluated in one pass per class.
//   * Post-pool feature maps are stored at 8 bits.
//   * External trained-weight ports are retained only for interface compatibility;
//     this fixed-model implementation embeds the searched coefficients. Bias ports
//     remain live inputs.
//
// Conv1 and Conv2 overlap as pooled values become available in the ring buffer.
// =============================================================================
`timescale 1ps/1ps

module cnn_inference_core (
    input  logic clk,
    input  logic rst_n,
    input  logic [7:0] data_in,
    output logic [3:0] decision,
    output logic valid_out_6,

    input [0:199]  w_11,
    input [0:199]  w_12,
    input [0:199]  w_13,
    input [0:23]   b_1,
    input [0:23]   b_2,
    input [0:199]  w_211,
    input [0:199]  w_212,
    input [0:199]  w_213,
    input [0:199]  w_221,
    input [0:199]  w_222,
    input [0:199]  w_223,
    input [0:199]  w_231,
    input [0:199]  w_232,
    input [0:199]  w_233,
    input [0:3839] w_fc,
    input [0:79]   b_fc
);

    import cnn_core_pkg::*;

    logic [1:0] state;
    logic last_c2_commit, fc_last_response;
    logic issue_c1, issue_c2;
    logic c1_tile_ready, c2_data_ready;
    logic [3:0] c1_issue_pr, c1_issue_pc;
    logic c1_issue_oc;
    logic [8:0] c1_commit_count;
    logic [2:0] c2_base_slot;
    logic [1:0] c2_issue_pr, c2_issue_pc, c2_issue_oc;
    logic c2_issue_ic;
    logic [3:0] fc_issue_class, rsp_fc_class;
    logic [4:0] fc_issue_count;
    logic signed [11:0] fc_score_now;
    logic [7:0] c1_window [0:5][0:5];
    logic [7:0] c2_tile [0:5][0:5];
    logic [7:0] fmap2 [0:2][0:3][0:3];

    logic req_valid, req_is_fc;
    logic [15:0] req_tag;
    logic signed [8:0] req_tile [0:5][0:5];
    logic signed [8:0] req_fc_a [0:47];

    logic rsp_valid, rsp_is_fc;
    logic [15:0] rsp_tag;
    logic signed [19:0] rsp_y00, rsp_y01, rsp_y10, rsp_y11;
    logic signed [15:0] rsp_fc_sum;

    always_ff @(posedge clk) begin
        if (!rst_n)
            state <= ST_STREAM;
        else if (fc_last_response)
            state <= ST_DONE;
        else if (last_c2_commit)
            state <= ST_FC;
    end

    conv1_input_window u_conv1_window (
        .clk, .rst_n, .issue_c1, .req_valid, .req_is_fc, .data_in,
        .c1_tile_ready, .c1_issue_pr, .c1_issue_pc, .c1_issue_oc, .c1_window
    );

    conv1_quantize_pool u_conv1_pool (
        .clk, .rst_n, .b_1, .rsp_valid, .rsp_is_fc, .rsp_tag,
        .rsp_y00, .rsp_y01, .rsp_y10, .rsp_y11,
        .c2_base_slot, .c2_issue_pc, .c2_issue_ic, .c1_commit_count, .c2_tile
    );

    conv2_accumulate_pool u_conv2 (
        .clk, .rst_n, .issue_c2, .req_valid, .req_is_fc, .b_2, .c1_commit_count,
        .rsp_valid, .rsp_is_fc, .rsp_tag, .rsp_y00, .rsp_y01, .rsp_y10, .rsp_y11,
        .c2_data_ready, .c2_issue_pr, .c2_issue_pc, .c2_issue_oc, .c2_issue_ic,
        .c2_base_slot, .fmap2, .last_c2_commit
    );

    fc_score_argmax u_fc (
        .clk, .rst_n, .last_c2_commit, .req_valid, .req_is_fc, .state,
        .rsp_valid, .rsp_is_fc, .rsp_tag, .rsp_fc_sum, .b_fc,
        .fc_issue_class, .fc_issue_count, .rsp_fc_class, .fc_score_now,
        .fc_last_response, .decision, .valid_out_6
    );

    engine_request_scheduler u_scheduler (
        .state, .c1_tile_ready, .c2_data_ready, .c1_issue_pr, .c1_issue_pc, .c1_issue_oc,
        .c2_issue_pr, .c2_issue_pc, .c2_issue_oc, .c2_issue_ic, .fc_issue_class,
        .fc_issue_count, .c1_window, .c2_tile, .fmap2,
        .issue_c1, .issue_c2, .req_valid, .req_is_fc, .req_tag, .req_tile, .req_fc_a
    );

    shared_shift_add_engine u_engine (
        .clk(clk), .rst_n(rst_n),
        .req_valid(req_valid), .req_is_fc(req_is_fc), .req_tag(req_tag),
        .conv_tile(req_tile), .fc_a(req_fc_a),
        .rsp_valid(rsp_valid), .rsp_is_fc(rsp_is_fc), .rsp_tag(rsp_tag),
        .conv_y00(rsp_y00), .conv_y01(rsp_y01),
        .conv_y10(rsp_y10), .conv_y11(rsp_y11),
        .fc_sum(rsp_fc_sum)
    );
endmodule
