`timescale 1ps/1ps

package cnn_core_pkg;
    localparam logic [1:0] ST_STREAM = 2'd0;
    localparam logic [1:0] ST_FC     = 2'd1;
    localparam logic [1:0] ST_DONE   = 2'd2;

    // Pool and apply ReLU in the 12-bit domain, then store the 8-bit result.
    function automatic logic [7:0] max4_relu_a8(
        input logic signed [11:0] a,
        input logic signed [11:0] b,
        input logic signed [11:0] c,
        input logic signed [11:0] d
    );
        logic signed [11:0] m0, m1, m;
        begin
            m0 = (a >= b) ? a : b;
            m1 = (c >= d) ? c : d;
            m  = (m0 >= m1) ? m0 : m1;
            if (m > 0)
                max4_relu_a8 = m[10:3];
            else
                max4_relu_a8 = 8'd0;
        end
    endfunction

    function automatic [2:0] add_mod7(
        input logic [2:0] base,
        input integer off
    );
        integer tmp;
        begin
            tmp = base + off;
            if (tmp >= 7) tmp = tmp - 7;
            add_mod7 = tmp[2:0];
        end
    endfunction
endpackage
