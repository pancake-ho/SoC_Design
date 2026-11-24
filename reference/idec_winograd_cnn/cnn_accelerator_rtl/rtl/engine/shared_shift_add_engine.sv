// Shared Conv/FC engine for model W477_A88_Cpot1-pot1-sp2_T32-0-0_M67.
`timescale 1ps/1ps

module shared_shift_add_engine (
    input  logic clk,
    input  logic rst_n,

    input  logic req_valid,
    input  logic req_is_fc,
    input  logic [15:0] req_tag,

    input  logic signed [8:0] conv_tile [0:5][0:5],
    input  logic signed [8:0] fc_a [0:47],

    output logic rsp_valid,
    output logic rsp_is_fc,
    output logic [15:0] rsp_tag,
    output logic signed [19:0] conv_y00,
    output logic signed [19:0] conv_y01,
    output logic signed [19:0] conv_y10,
    output logic signed [19:0] conv_y11,
    output logic signed [15:0] fc_sum
);

    logic p1_valid, p1_is_fc, p3_valid, p3_is_fc;
    logic [15:0] p1_tag, p3_tag;
    logic signed [10:0] p2_a_comb [0:48];
    wire signed [31:0] p3_p [0:48];

    input_tile_transform u_input_transform (
        .clk, .rst_n, .req_valid, .req_is_fc, .req_tag, .conv_tile, .fc_a,
        .p1_valid, .p1_is_fc, .p1_tag, .p2_a_comb
    );

    shift_add_lane_array u_lane_bank (
        .clk, .rst_n, .p1_valid, .p1_is_fc, .p1_tag, .p2_a_comb,
        .p3_valid, .p3_is_fc, .p3_tag, .p3_p
    );

    output_transform_reduce u_output_reduce (
        .clk, .rst_n, .p3_valid, .p3_is_fc, .p3_tag, .p3_p,
        .rsp_valid, .rsp_is_fc, .rsp_tag,
        .conv_y00, .conv_y01, .conv_y10, .conv_y11, .fc_sum
    );
endmodule
