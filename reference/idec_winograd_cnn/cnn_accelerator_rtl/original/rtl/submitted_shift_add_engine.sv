// Generated V28A: W477_A88_Cpot1-pot1-sp2_T32-0-0_M67.
`timescale 1ps/1ps

module pfdw_pipe49_shiftadd_engine_v28a (
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

    logic p1_valid,p1_is_fc;
    logic [15:0] p1_tag;
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

    logic signed [10:0] p2_a_comb [0:48];
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

    logic p2_valid,p2_is_fc,p3_valid,p3_is_fc;
    logic [15:0] p2_tag,p3_tag;
    wire signed [31:0] p3_p [0:48];

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

    generate        if (1) begin : G_LANE_0
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd3: begin coeff0=-12'sd32;coeff1=12'sd4;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd1;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd7: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd9: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd128;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[0]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[0][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_1
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd2: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd32;coeff1=12'sd2;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd6: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd7: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd8: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[1]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[1][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_2
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd1: begin coeff0=12'sd32;coeff1=-12'sd1;end
                        4'd2: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd3: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd7: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[2]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[2][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_3
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd2: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd3: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd5: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd7: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd128;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[3]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[3][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_4
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd4: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd8: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd128;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[4]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[4][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_5
            localparam integer AW=11, PW=18, TW=18;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[10]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd1: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd7: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd8: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd128;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[5]={{14{p3_p_q[17]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[5][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_6
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd8: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd1;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[6]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[6][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_7
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd32;coeff1=-12'sd4;end
                        4'd6: begin coeff0=-12'sd32;coeff1=-12'sd8;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd1;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd128;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[7]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[7][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_8
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd3: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd4: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd5: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd9: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[8]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[8][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_9
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd3: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd5: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[9]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[9][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_10
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd7: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[10]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[10][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_11
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd2: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd6: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd7: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[11]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[11][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_12
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd2: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd4: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd6: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd7: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd128;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[12]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[12][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_13
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd16;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd32;coeff1=12'sd4;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd5: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd6: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd9: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[13]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[13][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_14
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd3: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd8: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[14]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[14][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_15
            localparam integer AW=10, PW=17, TW=17;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd2: begin coeff0=-12'sd32;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd5: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd6: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd7: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd128;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[15]={{15{p3_p_q[16]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[15][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_16
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        4'd3: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd4: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd5: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd6: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[16]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[16][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_17
            localparam integer AW=9, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd16;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd2: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd6: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd16;coeff1=-12'sd2;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd1;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[17]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[17][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_18
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd2: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd4: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd5: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd7: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd8: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[18]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[18][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_19
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd6: begin coeff0=-12'sd32;coeff1=12'sd1;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd8: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        2'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[19]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[19][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_20
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd7: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        2'd1: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[20]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[20][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_21
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd4;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd3: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd6: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd16;coeff1=-12'sd2;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[21]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[21][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_22
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd9: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[22]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[22][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_23
            localparam integer AW=9, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd4: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd7: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd8: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd9: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[23]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[23][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_24
            localparam integer AW=10, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{4{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd4: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd8: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd9: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[24]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[24][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_25
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd2;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd4;end
                        4'd2: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd2;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd32;coeff1=12'sd2;end
                        4'd7: begin coeff0=-12'sd32;coeff1=12'sd2;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[25]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[25][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_26
            localparam integer AW=9, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd1: begin coeff0=12'sd32;coeff1=-12'sd4;end
                        4'd2: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd3: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd4: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd5: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd6: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd7: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=-12'sd8;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd128;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[26]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[26][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_27
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd3: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd6: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd7: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd9: begin coeff0=12'sd2;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[27]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[27][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_28
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd2: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd4: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd32;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd8: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[28]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[28][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_29
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd4: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd6: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd7: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd9: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[29]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[29][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_30
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd3: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd4: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd8: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[30]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[30][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_31
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd16;coeff1=-12'sd2;end
                        4'd1: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd2: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd3: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd6: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[31]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[31][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_32
            localparam integer AW=9, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd1: begin coeff0=-12'sd16;coeff1=-12'sd1;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd3: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd9: begin coeff0=12'sd16;coeff1=12'sd8;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd64;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[32]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[32][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_33
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd2: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd4: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[33]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[33][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_34
            localparam integer AW=9, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd2: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd6: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd9: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[34]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[34][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_35
            localparam integer AW=9, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{7{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd2: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd3: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd6: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd8: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd9: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd128;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[35]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[35][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_36
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd8: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd32;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[36]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[36][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_37
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd1: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd6: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd8: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[37]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[37][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_38
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd4: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd32;coeff1=-12'sd4;end
                        4'd6: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd7: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd1;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[38]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[38][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_39
            localparam integer AW=10, PW=16, TW=16;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd2: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd4: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd2;end
                        4'd6: begin coeff0=-12'sd4;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd8: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd1;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[39]={{16{p3_p_q[15]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[39][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_40
            localparam integer AW=10, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{4{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd1: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd2: begin coeff0=12'sd32;coeff1=-12'sd1;end
                        4'd3: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd5: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd6: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd7: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd9: begin coeff0=-12'sd32;coeff1=12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[40]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[40][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_41
            localparam integer AW=9, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd3: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=-12'sd8;end
                        4'd5: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd6: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd7: begin coeff0=12'sd16;coeff1=12'sd4;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd9: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[41]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[41][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_42
            localparam integer AW=10, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{4{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd3: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd1;end
                        4'd6: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd4;end
                        4'd8: begin coeff0=-12'sd16;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[42]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[42][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_43
            localparam integer AW=9, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd2;end
                        4'd1: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd2: begin coeff0=12'sd8;coeff1=12'sd1;end
                        4'd3: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd4: begin coeff0=-12'sd8;coeff1=-12'sd2;end
                        4'd5: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd6: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd7: begin coeff0=12'sd16;coeff1=-12'sd2;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd2;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[43]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[43][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_44
            localparam integer AW=9, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{6{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd2: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd3: begin coeff0=-12'sd8;coeff1=-12'sd1;end
                        4'd4: begin coeff0=12'sd4;coeff1=12'sd1;end
                        4'd5: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd6: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd7: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd8: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd8;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd16;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd16;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd64;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[44]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[44][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_45
            localparam integer AW=9, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd1: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd2: begin coeff0=-12'sd8;coeff1=12'sd0;end
                        4'd3: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=-12'sd1;end
                        4'd6: begin coeff0=-12'sd16;coeff1=-12'sd4;end
                        4'd7: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd16;coeff1=12'sd1;end
                        4'd9: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd8: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd1;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[45]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[45][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_46
            localparam integer AW=10, PW=15, TW=15;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=-12'sd4;coeff1=-12'sd2;end
                        4'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd16;coeff1=12'sd2;end
                        4'd3: begin coeff0=12'sd16;coeff1=12'sd8;end
                        4'd4: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd5: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd6: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd7: begin coeff0=12'sd8;coeff1=12'sd2;end
                        4'd8: begin coeff0=-12'sd2;coeff1=-12'sd1;end
                        4'd9: begin coeff0=12'sd4;coeff1=12'sd1;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd1;coeff1=12'sd0;end
                        4'd1: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[46]={{17{p3_p_q[14]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[46][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_47
            localparam integer AW=9, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{5{p2_a_q[8]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        4'd0: begin coeff0=12'sd4;coeff1=12'sd2;end
                        4'd1: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        4'd2: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd3: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=-12'sd8;coeff1=12'sd1;end
                        4'd5: begin coeff0=12'sd8;coeff1=-12'sd1;end
                        4'd6: begin coeff0=12'sd2;coeff1=12'sd1;end
                        4'd7: begin coeff0=-12'sd8;coeff1=-12'sd4;end
                        4'd8: begin coeff0=-12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=-12'sd4;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd4;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd0;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd32;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd8;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[47]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[47][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
        if (1) begin : G_LANE_48
            localparam integer AW=10, PW=14, TW=14;
            logic signed [AW-1:0] p2_a_q;
            logic signed [PW-1:0] p3_p_q;
            logic signed [11:0] coeff0,coeff1;
            logic signed [TW-1:0] term0,term1;
            wire signed [TW-1:0] a_ext = {{4{p2_a_q[9]}}, p2_a_q};
            wire signed [TW-1:0] product = $signed(term0)+$signed(term1);
            always_comb begin
                coeff0=9'sd0;coeff1=9'sd0;
                if(p2_is_fc) begin
                    case(p2_tag[3:0])
                        default: begin end
                    endcase
                end else if(!p2_tag[15]) begin
                    case(p2_tag[3:2])
                        2'd0: begin coeff0=12'sd2;coeff1=12'sd0;end
                        2'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end else begin
                    case({p2_tag[3:2],p2_tag[1:0]})
                        4'd0: begin coeff0=12'sd16;coeff1=12'sd0;end
                        4'd1: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd4: begin coeff0=12'sd8;coeff1=12'sd0;end
                        4'd5: begin coeff0=12'sd4;coeff1=12'sd0;end
                        4'd8: begin coeff0=12'sd2;coeff1=12'sd0;end
                        4'd9: begin coeff0=12'sd2;coeff1=12'sd0;end
                        default: begin end
                    endcase
                end
                case(coeff0)
                    -12'sd1: term0=-$signed(a_ext);
                    -12'sd2: term0=-($signed(a_ext) <<< 1);
                    -12'sd4: term0=-($signed(a_ext) <<< 2);
                    -12'sd8: term0=-($signed(a_ext) <<< 3);
                    -12'sd16: term0=-($signed(a_ext) <<< 4);
                    -12'sd32: term0=-($signed(a_ext) <<< 5);
                    -12'sd64: term0=-($signed(a_ext) <<< 6);
                    -12'sd128: term0=-($signed(a_ext) <<< 7);
                    -12'sd256: term0=-($signed(a_ext) <<< 8);
                    -12'sd512: term0=-($signed(a_ext) <<< 9);
                    -12'sd1024: term0=-($signed(a_ext) <<< 10);
                    12'sd1: term0=$signed(a_ext);
                    12'sd2: term0=($signed(a_ext) <<< 1);
                    12'sd4: term0=($signed(a_ext) <<< 2);
                    12'sd8: term0=($signed(a_ext) <<< 3);
                    12'sd16: term0=($signed(a_ext) <<< 4);
                    12'sd32: term0=($signed(a_ext) <<< 5);
                    12'sd64: term0=($signed(a_ext) <<< 6);
                    12'sd128: term0=($signed(a_ext) <<< 7);
                    12'sd256: term0=($signed(a_ext) <<< 8);
                    12'sd512: term0=($signed(a_ext) <<< 9);
                    12'sd1024: term0=($signed(a_ext) <<< 10);
                    default: term0='0;
                endcase
                case(coeff1)
                    -12'sd1: term1=-$signed(a_ext);
                    -12'sd2: term1=-($signed(a_ext) <<< 1);
                    -12'sd4: term1=-($signed(a_ext) <<< 2);
                    -12'sd8: term1=-($signed(a_ext) <<< 3);
                    -12'sd16: term1=-($signed(a_ext) <<< 4);
                    -12'sd32: term1=-($signed(a_ext) <<< 5);
                    -12'sd64: term1=-($signed(a_ext) <<< 6);
                    -12'sd128: term1=-($signed(a_ext) <<< 7);
                    -12'sd256: term1=-($signed(a_ext) <<< 8);
                    -12'sd512: term1=-($signed(a_ext) <<< 9);
                    -12'sd1024: term1=-($signed(a_ext) <<< 10);
                    12'sd1: term1=$signed(a_ext);
                    12'sd2: term1=($signed(a_ext) <<< 1);
                    12'sd4: term1=($signed(a_ext) <<< 2);
                    12'sd8: term1=($signed(a_ext) <<< 3);
                    12'sd16: term1=($signed(a_ext) <<< 4);
                    12'sd32: term1=($signed(a_ext) <<< 5);
                    12'sd64: term1=($signed(a_ext) <<< 6);
                    12'sd128: term1=($signed(a_ext) <<< 7);
                    12'sd256: term1=($signed(a_ext) <<< 8);
                    12'sd512: term1=($signed(a_ext) <<< 9);
                    12'sd1024: term1=($signed(a_ext) <<< 10);
                    default: term1='0;
                endcase
            end
            assign p3_p[48]={{18{p3_p_q[13]}}, p3_p_q};
            always_ff @(posedge clk) begin
                if(p1_valid) p2_a_q<=p2_a_comb[48][AW-1:0];
                if(p2_valid) p3_p_q<=product[PW-1:0];
            end
        end
    endgenerate
    logic p4_valid,p4_is_fc;
    logic [15:0] p4_tag;
    logic signed [15:0] p4_fc_grp[0:15];
    logic signed [18:0] p4_h33[0:3][0:1];
    logic signed [16:0] p4_h32[0:3][0:1];
    logic signed [17:0] p4_h23[0:2][0:1];
    logic signed [15:0] p4_h22[0:2][0:1];
    function automatic logic signed [31:0] plus3(input logic signed [31:0] a,b,c);
        plus3=a+b+c;
    endfunction
    function automatic logic signed [31:0] minus3(input logic signed [31:0] a,b,c);
        minus3=a-b-c;
    endfunction
    integer r,g;
    always_ff @(posedge clk) begin
        if(!rst_n) begin p4_valid<=0;p4_is_fc<=0;p4_tag<=0;end
        else begin
            p4_valid<=p3_valid;
            if(p3_valid) begin
                p4_is_fc<=p3_is_fc;p4_tag<=p3_tag;
                if(p3_is_fc) begin
                    for(g=0;g<16;g=g+1)
                        p4_fc_grp[g]<=plus3($signed(p3_p[g*3]),$signed(p3_p[g*3+1]),$signed(p3_p[g*3+2]));
                end else begin
                    p4_h33[0][0]<=plus3($signed(p3_p[0]),$signed(p3_p[1]),$signed(p3_p[2]));
                    p4_h33[0][1]<=minus3($signed(p3_p[1]),$signed(p3_p[2]),$signed(p3_p[3]));
                    p4_h33[1][0]<=plus3($signed(p3_p[4]),$signed(p3_p[5]),$signed(p3_p[6]));
                    p4_h33[1][1]<=minus3($signed(p3_p[5]),$signed(p3_p[6]),$signed(p3_p[7]));
                    p4_h33[2][0]<=plus3($signed(p3_p[8]),$signed(p3_p[9]),$signed(p3_p[10]));
                    p4_h33[2][1]<=minus3($signed(p3_p[9]),$signed(p3_p[10]),$signed(p3_p[11]));
                    p4_h33[3][0]<=plus3($signed(p3_p[12]),$signed(p3_p[13]),$signed(p3_p[14]));
                    p4_h33[3][1]<=minus3($signed(p3_p[13]),$signed(p3_p[14]),$signed(p3_p[15]));
                    p4_h32[0][0]<=plus3($signed(p3_p[16]),$signed(p3_p[17]),32'sd0);
                    p4_h32[0][1]<=plus3($signed(p3_p[17]),$signed(p3_p[18]),32'sd0);
                    p4_h32[1][0]<=plus3($signed(p3_p[19]),$signed(p3_p[20]),32'sd0);
                    p4_h32[1][1]<=plus3($signed(p3_p[20]),$signed(p3_p[21]),32'sd0);
                    p4_h32[2][0]<=plus3($signed(p3_p[22]),$signed(p3_p[23]),32'sd0);
                    p4_h32[2][1]<=plus3($signed(p3_p[23]),$signed(p3_p[24]),32'sd0);
                    p4_h32[3][0]<=plus3($signed(p3_p[25]),$signed(p3_p[26]),32'sd0);
                    p4_h32[3][1]<=plus3($signed(p3_p[26]),$signed(p3_p[27]),32'sd0);
                    p4_h23[0][0]<=plus3($signed(p3_p[28]),$signed(p3_p[29]),$signed(p3_p[30]));
                    p4_h23[0][1]<=minus3($signed(p3_p[29]),$signed(p3_p[30]),$signed(p3_p[31]));
                    p4_h23[1][0]<=plus3($signed(p3_p[32]),$signed(p3_p[33]),$signed(p3_p[34]));
                    p4_h23[1][1]<=minus3($signed(p3_p[33]),$signed(p3_p[34]),$signed(p3_p[35]));
                    p4_h23[2][0]<=plus3($signed(p3_p[36]),$signed(p3_p[37]),$signed(p3_p[38]));
                    p4_h23[2][1]<=minus3($signed(p3_p[37]),$signed(p3_p[38]),$signed(p3_p[39]));
                    p4_h22[0][0]<=plus3($signed(p3_p[40]),$signed(p3_p[41]),32'sd0);
                    p4_h22[0][1]<=plus3($signed(p3_p[41]),$signed(p3_p[42]),32'sd0);
                    p4_h22[1][0]<=plus3($signed(p3_p[43]),$signed(p3_p[44]),32'sd0);
                    p4_h22[1][1]<=plus3($signed(p3_p[44]),$signed(p3_p[45]),32'sd0);
                    p4_h22[2][0]<=plus3($signed(p3_p[46]),$signed(p3_p[47]),32'sd0);
                    p4_h22[2][1]<=plus3($signed(p3_p[47]),$signed(p3_p[48]),32'sd0);
                end
            end
        end
    end
    logic p5_valid,p5_is_fc;
    logic [15:0] p5_tag;
    logic signed [15:0] p5_fc_grp4[0:3];
    logic signed [19:0] p5_b0[0:3];
    logic signed [18:0] p5_b1[0:3];
    logic signed [18:0] p5_b2[0:3];
    logic signed [16:0] p5_b3[0:3];
    integer k;
    always_ff @(posedge clk) begin
        if(!rst_n) begin p5_valid<=0;p5_is_fc<=0;p5_tag<=0;end
        else begin
            p5_valid<=p4_valid;
            if(p4_valid) begin
                p5_is_fc<=p4_is_fc;p5_tag<=p4_tag;
                if(p4_is_fc) begin
                    for(k=0;k<4;k=k+1)
                        p5_fc_grp4[k]<=$signed(p4_fc_grp[k*4])+$signed(p4_fc_grp[k*4+1])
                                      +$signed(p4_fc_grp[k*4+2])+$signed(p4_fc_grp[k*4+3]);
                end else begin
                    p5_b0[0]<=plus3($signed(p4_h33[0][0]),$signed(p4_h33[1][0]),$signed(p4_h33[2][0]));
                    p5_b0[1]<=plus3($signed(p4_h33[0][1]),$signed(p4_h33[1][1]),$signed(p4_h33[2][1]));
                    p5_b0[2]<=minus3($signed(p4_h33[1][0]),$signed(p4_h33[2][0]),$signed(p4_h33[3][0]));
                    p5_b0[3]<=minus3($signed(p4_h33[1][1]),$signed(p4_h33[2][1]),$signed(p4_h33[3][1]));
                    p5_b1[0]<=plus3($signed(p4_h32[0][0]),$signed(p4_h32[1][0]),$signed(p4_h32[2][0]));
                    p5_b1[1]<=plus3($signed(p4_h32[0][1]),$signed(p4_h32[1][1]),$signed(p4_h32[2][1]));
                    p5_b1[2]<=minus3($signed(p4_h32[1][0]),$signed(p4_h32[2][0]),$signed(p4_h32[3][0]));
                    p5_b1[3]<=minus3($signed(p4_h32[1][1]),$signed(p4_h32[2][1]),$signed(p4_h32[3][1]));
                    p5_b2[0]<=plus3($signed(p4_h23[0][0]),$signed(p4_h23[1][0]),32'sd0);
                    p5_b2[1]<=plus3($signed(p4_h23[0][1]),$signed(p4_h23[1][1]),32'sd0);
                    p5_b2[2]<=plus3($signed(p4_h23[1][0]),$signed(p4_h23[2][0]),32'sd0);
                    p5_b2[3]<=plus3($signed(p4_h23[1][1]),$signed(p4_h23[2][1]),32'sd0);
                    p5_b3[0]<=plus3($signed(p4_h22[0][0]),$signed(p4_h22[1][0]),32'sd0);
                    p5_b3[1]<=plus3($signed(p4_h22[0][1]),$signed(p4_h22[1][1]),32'sd0);
                    p5_b3[2]<=plus3($signed(p4_h22[1][0]),$signed(p4_h22[2][0]),32'sd0);
                    p5_b3[3]<=plus3($signed(p4_h22[1][1]),$signed(p4_h22[2][1]),32'sd0);
                end
            end
        end
    end
    logic signed [31:0] y[0:3];
    logic signed [15:0] fc_mod16;
    integer q;
    always_comb begin
        y[0]=($signed({{12{p5_b0[0][19]}}, p5_b0[0]}) >>> 2)+($signed({{13{p5_b1[0][18]}}, p5_b1[0]}) >>> 1)+($signed({{13{p5_b2[0][18]}}, p5_b2[0]}) >>> 1)+($signed({{15{p5_b3[0][16]}}, p5_b3[0]}) >>> 0);
        y[1]=($signed({{12{p5_b0[1][19]}}, p5_b0[1]}) >>> 2)+($signed({{13{p5_b1[1][18]}}, p5_b1[1]}) >>> 1)+($signed({{13{p5_b2[1][18]}}, p5_b2[1]}) >>> 1)+($signed({{15{p5_b3[1][16]}}, p5_b3[1]}) >>> 0);
        y[2]=($signed({{12{p5_b0[2][19]}}, p5_b0[2]}) >>> 2)+($signed({{13{p5_b1[2][18]}}, p5_b1[2]}) >>> 1)+($signed({{13{p5_b2[2][18]}}, p5_b2[2]}) >>> 1)+($signed({{15{p5_b3[2][16]}}, p5_b3[2]}) >>> 0);
        y[3]=($signed({{12{p5_b0[3][19]}}, p5_b0[3]}) >>> 2)+($signed({{13{p5_b1[3][18]}}, p5_b1[3]}) >>> 1)+($signed({{13{p5_b2[3][18]}}, p5_b2[3]}) >>> 1)+($signed({{15{p5_b3[3][16]}}, p5_b3[3]}) >>> 0);
        fc_mod16=$signed(p5_fc_grp4[0])+$signed(p5_fc_grp4[1])+$signed(p5_fc_grp4[2])+$signed(p5_fc_grp4[3]);
    end
    always_ff @(posedge clk) begin
        if(!rst_n) begin
            rsp_valid<=0;rsp_is_fc<=0;rsp_tag<=0;
            conv_y00<=0;conv_y01<=0;conv_y10<=0;conv_y11<=0;fc_sum<=0;
        end else begin
            rsp_valid<=p5_valid;
            if(p5_valid) begin
                rsp_is_fc<=p5_is_fc;rsp_tag<=p5_tag;
                if(p5_is_fc) fc_sum<=fc_mod16;
                else begin conv_y00<=y[0][19:0];conv_y01<=y[1][19:0];conv_y10<=y[2][19:0];conv_y11<=y[3][19:0];end
            end
        end
    end
endmodule
