`timescale 1ps/1ps
// Capture 28x28 pixels and issue stride-2 Conv1 windows.
module conv1_input_window (
    input logic clk, rst_n,
    input logic issue_c1,
    input logic req_valid, req_is_fc,
    input logic [7:0] data_in,
    output logic c1_tile_ready,
    output logic [3:0] c1_issue_pr, c1_issue_pc,
    output logic c1_issue_oc,
    output logic [7:0] c1_window [0:5][0:5]
);
    import cnn_core_pkg::*;

    // -------------------------------------------------------------------------
    // External input stream storage.
    // Explicit row/col/slot counters replace /28, %28 and %7 address arithmetic.
    // -------------------------------------------------------------------------
    logic [7:0] linebuf [0:6][0:27];
    logic [9:0] pixels_stored;
    logic       capture_primed;
    logic [4:0] cap_row, cap_col;
    logic [2:0] cap_slot;

    // Conv1 local 6x6 sliding window.
    // The engine sees only this register bank, not a dynamic 7x28 column mux.
    logic               c1_window_valid;
    logic [4:0]         c1_new_col;  // two entering columns for next stride-2 tile

    // -------------------------------------------------------------------------
    // Conv1 progress.
    // c1_base_slot = (2*c1_issue_pr) mod 7, maintained incrementally.
    // -------------------------------------------------------------------------
    logic [2:0] c1_base_slot;
    logic [8:0] c1_issue_count;
    integer c1wr, c1wc;

    assign c1_tile_ready = (c1_issue_count < 9'd288) && c1_window_valid;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            pixels_stored <= 10'd0;
            capture_primed <= 1'b0;
            cap_row <= 0;
            cap_col <= 0;
            cap_slot <= 0;
            c1_window_valid <= 1'b0;
            c1_new_col <= 5'd6;
            c1_issue_pr <= 0; c1_issue_pc <= 0; c1_issue_oc <= 0;
            c1_base_slot <= 0;
            c1_issue_count <= 0;
        end else begin
            // Input capture continues independently of C1/C2 scheduling.
            if (pixels_stored < 10'd784) begin
                if (!capture_primed) begin
                    capture_primed <= 1'b1;
                end else begin
                    linebuf[cap_slot][cap_col] <= data_in;
                    pixels_stored <= pixels_stored + 1'b1;

                    // Row-start preload for the current Conv1 pooled row.
                    // It fires on the exact edge that captures raw column 5 of
                    // the sixth required input row. All other 35 bytes already
                    // reside in the seven-row line buffer; the just-arriving
                    // bottom-right byte bypasses the linebuf NBA write.
                    if (!c1_window_valid &&
                        (c1_issue_pc == 4'd0) &&
                        (c1_issue_oc == 2'd0) &&
                        (cap_col == 5'd5) &&
                        (cap_row == ({c1_issue_pr,1'b0} + 5'd5))) begin
                        for (c1wr = 0; c1wr < 6; c1wr = c1wr + 1) begin
                            for (c1wc = 0; c1wc < 6; c1wc = c1wc + 1) begin
                                if ((c1wr == 5) && (c1wc == 5))
                                    c1_window[c1wr][c1wc] <= data_in;
                                else
                                    c1_window[c1wr][c1wc] <=
                                        linebuf[add_mod7(c1_base_slot,c1wr)][c1wc];
                            end
                        end
                        c1_window_valid <= 1'b1;
                        c1_new_col <= 5'd6;
                    end

                    if (cap_col == 5'd27) begin
                        cap_col <= 0;
                        if (cap_row < 5'd27)
                            cap_row <= cap_row + 1'b1;
                        cap_slot <= (cap_slot == 3'd6) ? 3'd0 : cap_slot + 1'b1;
                    end else begin
                        cap_col <= cap_col + 1'b1;
                    end
                end
            end

            // Request-side progress. Conv1 reuses the same local 6x6 window
            // for the two surviving output channels. After physical channel 1, the
            // window advances by stride 2: four columns are retained and only two entering
            // columns (12 bytes total) are fetched from linebuf.
            if (req_valid && !req_is_fc && issue_c1) begin
                c1_issue_count <= c1_issue_count + 1'b1;
                if (c1_issue_oc == 1'b0) begin
                    c1_issue_oc <= 1'b1;
                end else begin
                    c1_issue_oc <= 0;
                    if (c1_issue_pc < 11) begin
                        for (c1wr = 0; c1wr < 6; c1wr = c1wr + 1) begin
                            c1_window[c1wr][0] <= c1_window[c1wr][2];
                            c1_window[c1wr][1] <= c1_window[c1wr][3];
                            c1_window[c1wr][2] <= c1_window[c1wr][4];
                            c1_window[c1wr][3] <= c1_window[c1wr][5];
                            c1_window[c1wr][4] <=
                                linebuf[add_mod7(c1_base_slot,c1wr)][c1_new_col];
                            // Bypass the line-buffer NBA write when the newest
                            // bottom-row pixel arrives on this edge.
                            if ((c1wr == 5) &&
                                (cap_row == ({c1_issue_pr,1'b0} + 5'd5)) &&
                                (cap_col == (c1_new_col + 1'b1)))
                                c1_window[c1wr][5] <= data_in;
                            else
                                c1_window[c1wr][5] <=
                                    linebuf[add_mod7(c1_base_slot,c1wr)][c1_new_col + 1'b1];
                        end
                        c1_new_col <= c1_new_col + 5'd2;
                        c1_issue_pc <= c1_issue_pc + 1'b1;
                    end else begin
                        // Next pooled row starts again at raw columns 0..5.
                        // Its window is reloaded by the input-capture preload
                        // above when the new bottom row reaches column 5.
                        c1_window_valid <= 1'b0;
                        c1_new_col <= 5'd6;
                        c1_issue_pc <= 0;
                        if (c1_issue_pr < 11) begin
                            c1_issue_pr <= c1_issue_pr + 1'b1;
                            c1_base_slot <= add_mod7(c1_base_slot,2);
                        end
                    end
                end
            end
        end
    end
endmodule
