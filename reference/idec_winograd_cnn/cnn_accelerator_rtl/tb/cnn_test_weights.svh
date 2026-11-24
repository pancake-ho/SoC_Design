// Weight and bias storage plus the original packed-port mapping.
    reg signed [7:0] weight_11 [0:24];
    reg signed [7:0] weight_12 [0:24];
    reg signed [7:0] weight_13 [0:24];
    reg signed [7:0] bias_1 [0:2];

    reg signed [7:0] bias_2 [0:2];
    reg signed [7:0] weight_211 [0:24];
    reg signed [7:0] weight_212 [0:24];
    reg signed [7:0] weight_213 [0:24];
    reg signed [7:0] weight_221 [0:24];
    reg signed [7:0] weight_222 [0:24];
    reg signed [7:0] weight_223 [0:24];
    reg signed [7:0] weight_231 [0:24];
    reg signed [7:0] weight_232 [0:24];
    reg signed [7:0] weight_233 [0:24];

    reg signed [7:0] weight_fc [0:479];
    reg signed [7:0] bias_fc [0:9];

    wire [0:199]  w_11, w_12, w_13;
    wire [0:23]   b_1, b_2;
    wire [0:199]  w_211, w_212, w_213;
    wire [0:199]  w_221, w_222, w_223;
    wire [0:199]  w_231, w_232, w_233;
    wire [0:3839] w_fc;
    wire [0:79]   b_fc;

    genvar gi;
    generate
        for (gi=0; gi<25; gi=gi+1) begin: PACK_CONV
            assign w_11 [(8*gi)+:8] = weight_11[gi];
            assign w_12 [(8*gi)+:8] = weight_12[gi];
            assign w_13 [(8*gi)+:8] = weight_13[gi];

            assign w_211[(8*gi)+:8] = weight_211[gi];
            assign w_212[(8*gi)+:8] = weight_212[gi];
            assign w_213[(8*gi)+:8] = weight_213[gi];

            assign w_221[(8*gi)+:8] = weight_221[gi];
            assign w_222[(8*gi)+:8] = weight_222[gi];
            assign w_223[(8*gi)+:8] = weight_223[gi];

            assign w_231[(8*gi)+:8] = weight_231[gi];
            assign w_232[(8*gi)+:8] = weight_232[gi];
            assign w_233[(8*gi)+:8] = weight_233[gi];
        end

        for (gi=0; gi<3; gi=gi+1) begin: PACK_BIAS_CONV
            assign b_1[(8*gi)+:8] = bias_1[gi];
            assign b_2[(8*gi)+:8] = bias_2[gi];
        end

        for (gi=0; gi<480; gi=gi+1) begin: PACK_FC
            assign w_fc[(8*gi)+:8] = weight_fc[gi];
        end

        for (gi=0; gi<10; gi=gi+1) begin: PACK_BIAS_FC
            assign b_fc[(8*gi)+:8] = bias_fc[gi];
        end
    endgenerate
