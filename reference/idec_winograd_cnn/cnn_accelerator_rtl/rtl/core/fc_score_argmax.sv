`timescale 1ps/1ps
// Track FC classes and calculate the fixed-point score and argmax.
module fc_score_argmax (
    input logic clk, rst_n,
    input logic last_c2_commit,
    input logic req_valid, req_is_fc,
    input logic [1:0] state,
    input logic rsp_valid, rsp_is_fc,
    input logic [15:0] rsp_tag,
    input logic signed [15:0] rsp_fc_sum,
    input logic [0:79] b_fc,
    output logic [3:0] fc_issue_class,
    output logic [4:0] fc_issue_count,
    output logic [3:0] rsp_fc_class,
    output logic signed [11:0] fc_score_now,
    output logic fc_last_response,
    output logic [3:0] decision,
    output logic valid_out_6
);
    import cnn_core_pkg::*;

    logic signed [11:0] best_score;
    logic [3:0] best_idx;
    logic signed [16:0] fc_class_sum;
    logic [15:0] fc_sum_mod16;
    logic [11:0] fc_base12;
    logic [2:0] fc_rem;
    logic signed [8:0] fc_low9;

    function automatic logic signed [7:0] get_fcb(input integer cls);
        get_fcb = $signed(b_fc[(8*cls)+:8]);
    endfunction

    assign rsp_fc_class = rsp_tag[3:0];
    assign fc_last_response = rsp_valid && rsp_is_fc && (rsp_fc_class == 4'd9);

    always_comb begin
        // Exact restore=4 FC score; modulo 2^16 is sufficient.
        // score = signed_slice(wrap20((sum<<4)+bias),18,7).
        fc_class_sum = $signed({rsp_fc_sum[15],rsp_fc_sum});
        fc_sum_mod16 = fc_class_sum[15:0];
        fc_base12 = fc_sum_mod16[14:3];
        fc_rem = fc_sum_mod16[2:0];
        fc_low9 = $signed({2'b00,fc_rem,4'b0000}) + $signed(get_fcb(rsp_fc_class));
        if (fc_low9 < 0)
            fc_score_now = $signed(fc_base12) - 12'sd1;
        else if (fc_low9 >= 9'sd128)
            fc_score_now = $signed(fc_base12) + 12'sd1;
        else
            fc_score_now = $signed(fc_base12);
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            fc_issue_class <= 0;
            fc_issue_count <= 0;
            best_score <= -12'sd2048;
            best_idx <= 0;

            decision <= 0;
            valid_out_6 <= 1'b0;
        end else begin
            valid_out_6 <= 1'b0;

            if (last_c2_commit) begin
                fc_issue_class <= 0;
                fc_issue_count <= 0;
                best_score <= -12'sd2048;
                best_idx <= 0;
            end

            if (req_valid && req_is_fc && state == ST_FC) begin
                fc_issue_count <= fc_issue_count + 1'b1;
                if(fc_issue_class<9) fc_issue_class<=fc_issue_class+1'b1;
            end

            // FC SP2: one response per class, no temporal term buffer.
            if(rsp_valid && rsp_is_fc) begin
                if(rsp_fc_class==0) begin best_score<=fc_score_now;best_idx<=0;end
                else if($signed(fc_score_now)>$signed(best_score)) begin
                    best_score<=fc_score_now;best_idx<=rsp_fc_class;
                end
                if(rsp_fc_class==9) begin
                    decision<=($signed(fc_score_now)>$signed(best_score))?4'd9:best_idx;
                    valid_out_6 <= 1'b1;
                end
            end
        end
    end
endmodule
