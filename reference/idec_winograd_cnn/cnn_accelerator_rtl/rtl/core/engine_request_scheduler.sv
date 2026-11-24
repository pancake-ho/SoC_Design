`timescale 1ps/1ps
// Arbitrate requests with Conv1 priority during streaming.
module engine_request_scheduler (
    input logic [1:0] state,
    input logic c1_tile_ready, c2_data_ready,
    input logic [3:0] c1_issue_pr, c1_issue_pc,
    input logic c1_issue_oc,
    input logic [1:0] c2_issue_pr, c2_issue_pc, c2_issue_oc,
    input logic c2_issue_ic,
    input logic [3:0] fc_issue_class,
    input logic [4:0] fc_issue_count,
    input logic [7:0] c1_window [0:5][0:5],
    input logic [7:0] c2_tile [0:5][0:5],
    input logic [7:0] fmap2 [0:2][0:3][0:3],
    output logic issue_c1, issue_c2,
    output logic req_valid, req_is_fc,
    output logic [15:0] req_tag,
    output logic signed [8:0] req_tile [0:5][0:5],
    output logic signed [8:0] req_fc_a [0:47]
);
    import cnn_core_pkg::*;

    integer rr, cc, lane, ch, pos;
    always_comb begin
        req_valid = 1'b0;
        req_is_fc = 1'b0;
        req_tag   = 16'd0;
        issue_c1  = 1'b0;
        issue_c2  = 1'b0;
        ch = 0;
        pos = 0;

        for (rr = 0; rr < 6; rr = rr + 1)
            for (cc = 0; cc < 6; cc = cc + 1)
                req_tile[rr][cc] = 9'sd0;

        for (lane = 0; lane < 48; lane = lane + 1) begin
            req_fc_a[lane] = 9'sd0;
        end

        if (state == ST_STREAM) begin
            if (c1_tile_ready) begin
                issue_c1 = 1'b1;
                req_valid = 1'b1;
                req_is_fc = 1'b0;
                req_tag = {1'b0, 3'b000, c1_issue_pr, c1_issue_pc, 1'b0, c1_issue_oc, 2'b00};

                // Fixed/local wiring: no c1_issue_pc-driven 28-column mux.
                for (rr = 0; rr < 6; rr = rr + 1)
                    for (cc = 0; cc < 6; cc = cc + 1)
                        req_tile[rr][cc] = {1'b0,c1_window[rr][cc]};
            end else if (c2_data_ready) begin
                issue_c2 = 1'b1;
                req_valid = 1'b1;
                req_is_fc = 1'b0;
                req_tag = {1'b1, 3'b000, {2'b00,c2_issue_pr},
                           {2'b00,c2_issue_pc}, c2_issue_oc, 1'b0, c2_issue_ic};

                for (rr = 0; rr < 6; rr = rr + 1)
                    for (cc = 0; cc < 6; cc = cc + 1)
                        req_tile[rr][cc] = {1'b0,c2_tile[rr][cc]};
            end
        end else if (state == ST_FC && fc_issue_count < 5'd10) begin
            req_valid = 1'b1;
            req_is_fc = 1'b1;
            req_tag = {12'd0,fc_issue_class};

            for (lane = 0; lane < 48; lane = lane + 1) begin
                ch  = lane / 16;
                pos = lane % 16;
                req_fc_a[lane] = {1'b0,fmap2[ch][pos/4][pos%4]};
            end
        end
    end
endmodule
