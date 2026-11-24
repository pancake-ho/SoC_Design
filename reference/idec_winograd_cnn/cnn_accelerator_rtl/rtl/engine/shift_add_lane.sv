`timescale 1ps/1ps
// A lane's operand truncation and two signed PoT terms wrap at the original widths.
module shift_add_lane #(
    parameter integer AW = 10,
    parameter integer PW = 17,
    parameter logic [47:0]  CONV1_COEFF = '0,
    parameter logic [143:0] CONV2_COEFF = '0,
    parameter logic [239:0] FC_COEFF = '0
) (
    input  logic clk, p1_valid, p2_valid, p2_is_fc,
    input  logic [15:0] p2_tag,
    input  logic signed [10:0] operand,
    output wire signed [31:0] result
);
    logic signed [AW-1:0] p2_a_q;
    logic signed [PW-1:0] p3_p_q;
    logic [23:0] coefficients;
    wire signed [PW-1:0] a_ext = {{(PW-AW){p2_a_q[AW-1]}}, p2_a_q};

    function automatic logic signed [PW-1:0] apply_pot(
        input logic signed [11:0] coefficient,
        input logic signed [PW-1:0] operand_signed
    );
        case (coefficient)
            -12'sd1: apply_pot=-$signed(operand_signed);
            -12'sd2: apply_pot=-($signed(operand_signed) <<< 1);
            -12'sd4: apply_pot=-($signed(operand_signed) <<< 2);
            -12'sd8: apply_pot=-($signed(operand_signed) <<< 3);
            -12'sd16: apply_pot=-($signed(operand_signed) <<< 4);
            -12'sd32: apply_pot=-($signed(operand_signed) <<< 5);
            -12'sd64: apply_pot=-($signed(operand_signed) <<< 6);
            -12'sd128: apply_pot=-($signed(operand_signed) <<< 7);
            -12'sd256: apply_pot=-($signed(operand_signed) <<< 8);
            -12'sd512: apply_pot=-($signed(operand_signed) <<< 9);
            -12'sd1024: apply_pot=-($signed(operand_signed) <<< 10);
            12'sd1: apply_pot=$signed(operand_signed);
            12'sd2: apply_pot=($signed(operand_signed) <<< 1);
            12'sd4: apply_pot=($signed(operand_signed) <<< 2);
            12'sd8: apply_pot=($signed(operand_signed) <<< 3);
            12'sd16: apply_pot=($signed(operand_signed) <<< 4);
            12'sd32: apply_pot=($signed(operand_signed) <<< 5);
            12'sd64: apply_pot=($signed(operand_signed) <<< 6);
            12'sd128: apply_pot=($signed(operand_signed) <<< 7);
            12'sd256: apply_pot=($signed(operand_signed) <<< 8);
            12'sd512: apply_pot=($signed(operand_signed) <<< 9);
            12'sd1024: apply_pot=($signed(operand_signed) <<< 10);
            default: apply_pot='0;
        endcase
    endfunction

    always_comb begin
        coefficients = '0;
        if (p2_is_fc) begin
            case (p2_tag[3:0])
                4'd0: coefficients = FC_COEFF[0*24+:24];
                4'd1: coefficients = FC_COEFF[1*24+:24];
                4'd2: coefficients = FC_COEFF[2*24+:24];
                4'd3: coefficients = FC_COEFF[3*24+:24];
                4'd4: coefficients = FC_COEFF[4*24+:24];
                4'd5: coefficients = FC_COEFF[5*24+:24];
                4'd6: coefficients = FC_COEFF[6*24+:24];
                4'd7: coefficients = FC_COEFF[7*24+:24];
                4'd8: coefficients = FC_COEFF[8*24+:24];
                4'd9: coefficients = FC_COEFF[9*24+:24];
                default: coefficients = '0;
            endcase
        end else if (!p2_tag[15]) begin
            case (p2_tag[3:2])
                2'd0: coefficients = CONV1_COEFF[0*24+:24];
                2'd1: coefficients = CONV1_COEFF[1*24+:24];
                default: coefficients = '0;
            endcase
        end else begin
            case ({p2_tag[3:2], p2_tag[1:0]})
                4'd0: coefficients = CONV2_COEFF[0*24+:24];
                4'd1: coefficients = CONV2_COEFF[1*24+:24];
                4'd4: coefficients = CONV2_COEFF[2*24+:24];
                4'd5: coefficients = CONV2_COEFF[3*24+:24];
                4'd8: coefficients = CONV2_COEFF[4*24+:24];
                4'd9: coefficients = CONV2_COEFF[5*24+:24];
                default: coefficients = '0;
            endcase
        end
    end

    wire signed [PW-1:0] term0 = apply_pot($signed(coefficients[23:12]), a_ext);
    wire signed [PW-1:0] term1 = apply_pot($signed(coefficients[11:0]), a_ext);
    wire signed [PW-1:0] product = $signed(term0) + $signed(term1);

    always_ff @(posedge clk) begin
        if (p1_valid)
            p2_a_q <= operand[AW-1:0];
        if (p2_valid)
            p3_p_q <= product;
    end

    assign result = {{(32-PW){p3_p_q[PW-1]}}, p3_p_q};
endmodule
