`timescale 1ps/1ps

module tb_shared_engine_equivalence;
    localparam int RESPONSE_DELAY = 6;
    logic clk = 0, rst_n = 0, req_valid = 0, req_is_fc = 0;
    logic [15:0] req_tag = '0;
    logic signed [8:0] conv_tile [0:5][0:5];
    logic signed [8:0] fc_a [0:47];

    wire rsp_valid, rsp_is_fc, original_valid, original_is_fc;
    wire [15:0] rsp_tag, original_tag;
    wire signed [19:0] y00, y01, y10, y11, original_y00, original_y01, original_y10, original_y11;
    wire signed [15:0] fc_sum, original_sum;

    logic [RESPONSE_DELAY:0] pending = '0;
    logic [RESPONSE_DELAY:0] pending_is_fc = '0;
    logic [15:0] pending_tag [0:RESPONSE_DELAY];
    int accepted = 0, received = 0, flushed = 0, lane_vectors = 0;
    logic [31:0] rng = 32'h2468_ace1;

    always #5ns clk = ~clk;

    shared_shift_add_engine dut (
        .clk, .rst_n, .req_valid, .req_is_fc, .req_tag, .conv_tile, .fc_a,
        .rsp_valid, .rsp_is_fc, .rsp_tag, .conv_y00(y00), .conv_y01(y01),
        .conv_y10(y10), .conv_y11(y11), .fc_sum
    );
    reference_shift_add_engine reference_engine (
        .clk, .rst_n, .req_valid, .req_is_fc, .req_tag, .conv_tile, .fc_a,
        .rsp_valid(original_valid), .rsp_is_fc(original_is_fc), .rsp_tag(original_tag),
        .conv_y00(original_y00), .conv_y01(original_y01),
        .conv_y10(original_y10), .conv_y11(original_y11), .fc_sum(original_sum)
    );

    function automatic logic signed [8:0] operand(input int pattern, input int index);
        case (pattern)
            0: operand = 9'sd0;
            1: operand = 9'sd255;
            2: operand = 9'sh100;  // -256
            3: operand = ((index % 2) == 0) ? 9'sd255 : 9'sh100;
            default: begin
                rng = rng ^ (rng << 13);
                rng = rng ^ (rng >> 17);
                rng = rng ^ (rng << 5);
                operand = rng[8:0];
            end
        endcase
    endfunction

    always @(posedge clk) begin
        if (!rst_n) begin
            // RESPONSE_DELAY entries have been accepted but haven't returned yet.
            flushed += $countones(pending[RESPONSE_DELAY-1:0]);
            pending = '0;
            pending_is_fc = '0;
        end else begin
            pending = {pending[RESPONSE_DELAY-1:0], req_valid};
            pending_is_fc = {pending_is_fc[RESPONSE_DELAY-1:0], req_is_fc};
            for (int stage = RESPONSE_DELAY; stage > 0; stage--)
                pending_tag[stage] = pending_tag[stage - 1];
            pending_tag[0] = req_tag;
            if (req_valid)
                accepted++;
        end

        #1ps;  // Sample registered outputs after NBA.
        if (rsp_valid !== pending[RESPONSE_DELAY] || rsp_valid !== original_valid)
            $fatal(1, "Response valid/latency mismatch at %t", $time);
        if ({rsp_is_fc, rsp_tag, y00, y01, y10, y11, fc_sum} !==
            {original_is_fc, original_tag, original_y00, original_y01,
             original_y10, original_y11, original_sum})
            $fatal(1, "Response output mismatch at %t for tag %h", $time, rsp_tag);
        if (rsp_valid) begin
            if (rsp_tag !== pending_tag[RESPONSE_DELAY] ||
                rsp_is_fc !== pending_is_fc[RESPONSE_DELAY])
                $fatal(1, "Response metadata mismatch for tag %h", rsp_tag);
            if (rsp_is_fc ? $isunknown(fc_sum) : $isunknown({y00, y01, y10, y11}))
                $fatal(1, "Unknown valid data for tag %h", rsp_tag);
            received++;
        end
        if (dut.p3_valid !== reference_engine.p3_valid)
            $fatal(1, "P3 valid mismatch at %t", $time);
        if (dut.p3_valid) begin
            for (int lane = 0; lane < 49; lane++)
                if ($isunknown(dut.p3_p[lane]) ||
                    dut.p3_p[lane] !== reference_engine.p3_p[lane])
                    $fatal(1, "P3 lane %0d mismatch for tag %h", lane, dut.p3_tag);
            lane_vectors++;
        end
    end

    initial begin
        for (int vector = 0; vector < 4096; vector++) begin
            @(negedge clk);
            // Cover all low-nibble tags for FC, Conv1 and Conv2, including defaults.
            rst_n = (vector != 1024 && vector != 2048);
            req_valid = (vector < 48 || vector % 11 != 0);
            req_is_fc = ((vector % 48) < 16);
            req_tag = {(vector % 48 >= 32), 11'(vector), 4'(vector % 16)};
            for (int row = 0; row < 6; row++)
                for (int col = 0; col < 6; col++)
                    conv_tile[row][col] = operand(vector / 48, row * 6 + col);
            for (int lane = 0; lane < 48; lane++)
                fc_a[lane] = operand(vector / 48, lane);
        end
        @(negedge clk);
        req_valid = 0;
        repeat (RESPONSE_DELAY + 2) @(negedge clk);
        if (accepted < 3700 || flushed == 0 || received != accepted - flushed)
            $fatal(1, "Incomplete traffic accepted=%0d received=%0d flushed=%0d", accepted, received, flushed);
        $display("ENGINE EQUIVALENCE PASS: accepted=%0d responses=%0d reset_flushed=%0d P3_vectors=%0d lanes_per_vector=49",
                 accepted, received, flushed, lane_vectors);
        $finish;
    end

    initial begin
        #100us;
        $fatal(1, "Engine timeout");
    end
endmodule
