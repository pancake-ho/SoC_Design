`timescale 1ps/1ps
// P0/P1 registers and P2 combinational input transform. FC bypasses the transform.
module input_tile_transform (
    input  logic clk, rst_n,
    input  logic req_valid, req_is_fc,
    input  logic [15:0] req_tag,
    input  logic signed [8:0] conv_tile [0:5][0:5],
    input  logic signed [8:0] fc_a [0:47],
    output logic p1_valid, p1_is_fc,
    output logic [15:0] p1_tag,
    output logic signed [10:0] p2_a_comb [0:48]
);

    function automatic logic signed [9:0] b3_h9(
        input logic signed [8:0] x0,
        input logic signed [8:0] x1,
        input logic signed [8:0] x2,
        input logic signed [8:0] x3,
        input integer o
    );
        logic signed [9:0] a0,a1,a2,a3;
        begin
            a0={x0[8],x0}; a1={x1[8],x1};
            a2={x2[8],x2}; a3={x3[8],x3};
            case(o)
                0: b3_h9 = a0-a2;
                1: b3_h9 = a1+a2;
                2: b3_h9 = -a1+a2;
                default: b3_h9 = a1-a3;
            endcase
        end
    endfunction

    function automatic logic signed [9:0] b2_h9(
        input logic signed [8:0] x0,
        input logic signed [8:0] x1,
        input logic signed [8:0] x2,
        input integer o
    );
        logic signed [9:0] a0,a1,a2;
        begin
            a0={x0[8],x0}; a1={x1[8],x1}; a2={x2[8],x2};
            case(o)
                0: b2_h9 = a0-a1;
                1: b2_h9 = a1;
                default: b2_h9 = -a1+a2;
            endcase
        end
    endfunction

    function automatic logic signed [10:0] b3_v10(
        input logic signed [9:0] x0,
        input logic signed [9:0] x1,
        input logic signed [9:0] x2,
        input logic signed [9:0] x3,
        input integer o
    );
        logic signed [10:0] a0,a1,a2,a3;
        begin
            a0={x0[9],x0}; a1={x1[9],x1};
            a2={x2[9],x2}; a3={x3[9],x3};
            case(o)
                0: b3_v10 = a0-a2;
                1: b3_v10 = a1+a2;
                2: b3_v10 = -a1+a2;
                default: b3_v10 = a1-a3;
            endcase
        end
    endfunction

    function automatic logic signed [10:0] b2_v10(
        input logic signed [9:0] x0,
        input logic signed [9:0] x1,
        input logic signed [9:0] x2,
        input integer o
    );
        logic signed [10:0] a0,a1,a2;
        begin
            a0={x0[9],x0}; a1={x1[9],x1}; a2={x2[9],x2};
            case(o)
                0: b2_v10 = a0-a1;
                1: b2_v10 = a1;
                default: b2_v10 = -a1+a2;
            endcase
        end
    endfunction

    logic p0_valid, p0_is_fc;
    logic [15:0] p0_tag;
    logic signed [8:0] p0_a [0:47];
    integer r0,c0,f0;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            p0_valid<=1'b0; p0_is_fc<=1'b0; p0_tag<=16'd0;
        end else begin
            p0_valid<=req_valid;
            if(req_valid) begin
                p0_is_fc<=req_is_fc; p0_tag<=req_tag;
                if(req_is_fc) begin
                    for(f0=0;f0<48;f0=f0+1) p0_a[f0] <= fc_a[f0];
                end else begin
                    for(r0=0;r0<6;r0=r0+1)
                        for(c0=0;c0<6;c0=c0+1)
                            p0_a[r0*6+c0] <= conv_tile[r0][c0];
                end
            end
        end
    end

    logic signed [9:0] p1_a [0:48];
    integer pr,po,pf;
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            p1_valid<=1'b0; p1_is_fc<=1'b0; p1_tag<=16'd0;
        end else begin
            p1_valid<=p0_valid;
            if(p0_valid) begin
                p1_is_fc<=p0_is_fc; p1_tag<=p0_tag;
                if(p0_is_fc) begin
                    for(pf=0;pf<48;pf=pf+1)
                        p1_a[pf] <= {p0_a[pf][8],p0_a[pf]};
                    p1_a[48] <= 10'sd0;
                end else begin
                    for(pr=0;pr<4;pr=pr+1)
                        for(po=0;po<4;po=po+1)
                            p1_a[pr*4+po] <= b3_h9(p0_a[pr*6+0],p0_a[pr*6+1],p0_a[pr*6+2],p0_a[pr*6+3],po);
                    for(pr=0;pr<4;pr=pr+1)
                        for(po=0;po<3;po=po+1)
                            p1_a[16+pr*3+po] <= b2_h9(p0_a[pr*6+3],p0_a[pr*6+4],p0_a[pr*6+5],po);
                    for(pr=0;pr<3;pr=pr+1)
                        for(po=0;po<4;po=po+1)
                            p1_a[28+pr*4+po] <= b3_h9(p0_a[(pr+3)*6+0],p0_a[(pr+3)*6+1],p0_a[(pr+3)*6+2],p0_a[(pr+3)*6+3],po);
                    for(pr=0;pr<3;pr=pr+1)
                        for(po=0;po<3;po=po+1)
                            p1_a[40+pr*3+po] <= b2_h9(p0_a[(pr+3)*6+3],p0_a[(pr+3)*6+4],p0_a[(pr+3)*6+5],po);
                end
            end
        end
    end

    integer pj,pi;
    always_comb begin
        for(pi=0;pi<49;pi=pi+1) p2_a_comb[pi]=11'sd0;
        if(p1_is_fc) begin
            for(pi=0;pi<48;pi=pi+1)
                p2_a_comb[pi] = {{1{p1_a[pi][9]}},p1_a[pi]};
        end else begin
            for(pj=0;pj<4;pj=pj+1)
                for(pi=0;pi<4;pi=pi+1)
                    p2_a_comb[pi*4+pj]=b3_v10(p1_a[0*4+pj],p1_a[1*4+pj],p1_a[2*4+pj],p1_a[3*4+pj],pi);
            for(pj=0;pj<3;pj=pj+1)
                for(pi=0;pi<4;pi=pi+1)
                    p2_a_comb[16+pi*3+pj]=b3_v10(p1_a[16+0*3+pj],p1_a[16+1*3+pj],p1_a[16+2*3+pj],p1_a[16+3*3+pj],pi);
            for(pj=0;pj<4;pj=pj+1)
                for(pi=0;pi<3;pi=pi+1)
                    p2_a_comb[28+pi*4+pj]=b2_v10(p1_a[28+0*4+pj],p1_a[28+1*4+pj],p1_a[28+2*4+pj],pi);
            for(pj=0;pj<3;pj=pj+1)
                for(pi=0;pi<3;pi=pi+1)
                    p2_a_comb[40+pi*3+pj]=b2_v10(p1_a[40+0*3+pj],p1_a[40+1*3+pj],p1_a[40+2*3+pj],pi);
        end
    end
endmodule
