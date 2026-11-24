`timescale 1ps/1ps
// P2 captures the transformed operand. P3 captures the shift-add product.
module shift_add_lane_array (
    input  logic clk, rst_n,
    input  logic p1_valid, p1_is_fc,
    input  logic [15:0] p1_tag,
    input  logic signed [10:0] p2_a_comb [0:48],
    output logic p3_valid, p3_is_fc,
    output logic [15:0] p3_tag,
    output wire signed [31:0] p3_p [0:48]
);
    logic p2_valid, p2_is_fc;
    logic [15:0] p2_tag;

    `include "lane_bit_widths.svh"
    `include "conv_coefficient_table.svh"
    `include "fc_coefficient_table.svh"

    always_ff @(posedge clk) begin
        if(!rst_n) begin
            p2_valid<=1'b0; p2_is_fc<=1'b0; p2_tag<=16'd0;
            p3_valid<=1'b0; p3_is_fc<=1'b0; p3_tag<=16'd0;
        end else begin
            p2_valid<=p1_valid;
            if(p1_valid) begin p2_is_fc<=p1_is_fc; p2_tag<=p1_tag; end
            p3_valid<=p2_valid;
            if(p2_valid) begin p3_is_fc<=p2_is_fc; p3_tag<=p2_tag; end
        end
    end

    for (genvar lane = 0; lane < 49; lane = lane + 1) begin : g_lane
        localparam logic [15:0] LANE_WIDTHS = lane_widths(lane);
        shift_add_lane #(
            .AW(int'(LANE_WIDTHS[15:8])), .PW(int'(LANE_WIDTHS[7:0])),
            .CONV1_COEFF(conv1_coefficients(lane)),
            .CONV2_COEFF(conv2_coefficients(lane)),
            .FC_COEFF(fc_coefficients(lane))
        ) u_lane (
            .clk, .p1_valid, .p2_valid, .p2_is_fc, .p2_tag,
            .operand(p2_a_comb[lane]), .result(p3_p[lane])
        );
    end
endmodule
