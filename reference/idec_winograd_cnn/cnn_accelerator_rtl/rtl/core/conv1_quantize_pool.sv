`timescale 1ps/1ps
// Quantize Conv1 responses, pool into a seven-row ring, and read Conv2 tiles.
module conv1_quantize_pool (
    input logic clk, rst_n,
    input logic [0:23] b_1,
    input logic rsp_valid, rsp_is_fc,
    input logic [15:0] rsp_tag,
    input logic signed [19:0] rsp_y00, rsp_y01, rsp_y10, rsp_y11,
    input logic [2:0] c2_base_slot,
    input logic [1:0] c2_issue_pc,
    input logic c2_issue_ic,
    output logic [8:0] c1_commit_count,
    output logic [7:0] c2_tile [0:5][0:5]
);
    import cnn_core_pkg::*;

    // The ring stores seven pooled rows as unsigned 8-bit values after ReLU.
    // Conv1 keeps two physical channels: 2 x 7 x 12 x 8 = 1344 payload bits.
    logic        [7:0] fmap1_ring [0:1][0:6][0:11];
    // Conv1 writeback pipeline. WB0 registers the four quantized values; the
    // following cycle performs only 4-way max/ReLU and commits to fmap1_ring.
    logic c1_wb_valid;
    logic [2:0] c1_wb_slot;
    logic [3:0] c1_wb_pc;
    logic       c1_wb_oc;
    logic signed [11:0] c1_wb_q00, c1_wb_q01, c1_wb_q10, c1_wb_q11;
    localparam integer C1_RESTORE_SHIFT = 4; // generated from selected configuration

    // Conv1 physical channel 0/1 corresponds to original channel 1/2.
    function automatic logic signed [7:0] get_b1(input integer phys_oc);
        begin
            case (phys_oc)
                0: get_b1 = $signed(b_1[8+:8]);
                1: get_b1 = $signed(b_1[16+:8]);
                default: get_b1 = 8'sd0;
            endcase
        end
    endfunction

    function automatic logic signed [11:0] conv1_q(
        input logic signed [31:0] raw,
        input logic signed [7:0] bias8
    );
        logic signed [19:0] t20;
        logic signed [11:0] shr12;
        logic signed [11:0] b12;
        logic signed [12:0] add13;
        begin
            t20   = raw[19:0];
            shr12 = $signed(t20) >>> 8;
            b12   = {{4{bias8[7]}},bias8};
            add13 = $signed(shr12) + $signed(b12);
            conv1_q = add13[11:0];
        end
    endfunction

    wire rsp_layer = rsp_tag[15];
    wire [3:0] rsp_pr = rsp_tag[11:8];
    wire [3:0] rsp_pc = rsp_tag[7:4];
    wire [1:0] rsp_oc = rsp_tag[3:2];
    logic signed [11:0] rsp_c1q00, rsp_c1q01, rsp_c1q10, rsp_c1q11;

    always_comb begin
        rsp_c1q00 = conv1_q($signed(rsp_y00) <<< C1_RESTORE_SHIFT,get_b1(rsp_oc));
        rsp_c1q01 = conv1_q($signed(rsp_y01) <<< C1_RESTORE_SHIFT,get_b1(rsp_oc));
        rsp_c1q10 = conv1_q($signed(rsp_y10) <<< C1_RESTORE_SHIFT,get_b1(rsp_oc));
        rsp_c1q11 = conv1_q($signed(rsp_y11) <<< C1_RESTORE_SHIFT,get_b1(rsp_oc));
    end

    // Conv2 reads the 6x6 window from one channel of the pooled ring.
    always_comb begin
        for (int row = 0; row < 6; row = row + 1)
            for (int col = 0; col < 6; col = col + 1)
                c2_tile[row][col] = fmap1_ring[c2_issue_ic]
                    [add_mod7(c2_base_slot,row)][c2_issue_pc*2+col];
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            c1_commit_count <= 0;
            c1_wb_valid <= 1'b0;
            c1_wb_slot <= 0; c1_wb_pc <= 0; c1_wb_oc <= 0;
            c1_wb_q00 <= 0; c1_wb_q01 <= 0;
            c1_wb_q10 <= 0; c1_wb_q11 <= 0;
        end else begin
            // Conv1 writeback pipeline. The response cycle performs only the
            // fixed-point quantization into WB0. The next cycle performs the
            // max/ReLU and writes one pooled value into the seven-row ring.
            c1_wb_valid <= 1'b0;
            if (c1_wb_valid) begin
                fmap1_ring[c1_wb_oc][c1_wb_slot][c1_wb_pc] <=
                    max4_relu_a8(c1_wb_q00,c1_wb_q01,c1_wb_q10,c1_wb_q11);
                c1_commit_count <= c1_commit_count + 1'b1;
            end

            // Conv1 response -> WB0 quantization register. Pool/ReLU and the
            // physical ring write occur on the following cycle above.
            if (rsp_valid && !rsp_is_fc && (rsp_layer == 1'b0)) begin
                c1_wb_valid <= 1'b1;
                c1_wb_slot <= add_mod7(3'd0,rsp_pr);
                c1_wb_pc <= rsp_pc;
                c1_wb_oc <= rsp_oc;
                c1_wb_q00 <= rsp_c1q00;
                c1_wb_q01 <= rsp_c1q01;
                c1_wb_q10 <= rsp_c1q10;
                c1_wb_q11 <= rsp_c1q11;
            end
        end
    end
endmodule
