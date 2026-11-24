`timescale 1ps/1ps
// P4/P5 partial reductions and P6 response. Intermediate widths define wrapping.
module output_transform_reduce (
    input  logic clk, rst_n,
    input  logic p3_valid, p3_is_fc,
    input  logic [15:0] p3_tag,
    input  logic signed [31:0] p3_p [0:48],
    output logic rsp_valid, rsp_is_fc,
    output logic [15:0] rsp_tag,
    output logic signed [19:0] conv_y00, conv_y01, conv_y10, conv_y11,
    output logic signed [15:0] fc_sum
);

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
    integer g;
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
