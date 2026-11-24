// Exact integer Winograd F(2x2, 3x3) for signed INT8 cross-correlation.
module winograd_tile_engine (
    input clk, reset, load_filter, start_tile,
    input [71:0] filter_values,
    input [127:0] input_tile,
    output reg result_valid,
    output reg [75:0] tile_sums
);
    localparam IDLE=3'd0, INPUT_VERTICAL=3'd1, LOAD_ROW=3'd2,
               MULTIPLY=3'd3, OUTPUT_VERTICAL=3'd4, OUTPUT_HORIZONTAL=3'd5;
    reg [2:0] state;
    reg filter_pending;
    reg [1:0] product_row;
    reg [2:0] digit_index;

    reg signed [9:0] filter_horizontal [0:11];
    reg signed [11:0] transformed_filter [0:15];
    reg signed [8:0] input_horizontal [0:15];
    reg signed [9:0] transformed_input [0:15];
    reg signed [21:0] products [0:15];
    reg signed [23:0] output_vertical [0:7];

    // Rows of 2G. Using 2G in both dimensions yields a factor of four.
    function signed [11:0] filter_transform;
        input signed [11:0] a, b, c;
        input [1:0] row;
        begin
            case (row)
                2'd0: filter_transform = a <<< 1;
                2'd1: filter_transform = a + b + c;
                2'd2: filter_transform = a - b + c;
                2'd3: filter_transform = c <<< 1;
            endcase
        end
    endfunction

    // Rows of B transpose, with the same sign convention as the IDEC 3-tap block.
    function signed [9:0] input_transform;
        input signed [9:0] a, b, c, d;
        input [1:0] row;
        begin
            case (row)
                2'd0: input_transform = a - c;
                2'd1: input_transform = b + c;
                2'd2: input_transform = c - b;
                2'd3: input_transform = b - d;
            endcase
        end
    endfunction

    // Rows of A transpose for the B transpose above.
    function signed [25:0] inverse_transform;
        input signed [25:0] a, b, c, d;
        input second;
        begin
            inverse_transform = second ? b - c - d : a + b + c;
        end
    endfunction

    // One signed radix-4 Booth digit. acc and x hold the full 10x12 product width.
    function signed [21:0] booth_sum;
        input signed [21:0] acc, x;
        input [2:0] digit;
        begin
            case (digit)
                3'b001, 3'b010: booth_sum = acc + x;
                3'b011:         booth_sum = acc + (x <<< 1);
                3'b100:         booth_sum = acc - (x <<< 1);
                3'b101, 3'b110: booth_sum = acc - x;
                default:        booth_sum = acc;
            endcase
        end
    endfunction

    wire signed [23:0] vertical_sum [0:7];
    wire signed [25:0] scaled_sum [0:3];
    genvar r, c;
    generate
        for (r=0; r<3; r=r+1) begin : filter_rows
            for (c=0; c<4; c=c+1) begin : column
                wire signed [11:0] value = filter_transform(
                    $signed(filter_values[(3*r)*8+:8]),
                    $signed(filter_values[(3*r+1)*8+:8]),
                    $signed(filter_values[(3*r+2)*8+:8]), c[1:0]);
                always @(posedge clk)
                    if (load_filter) filter_horizontal[4*r+c] <= value[9:0];
            end
        end
        for (r=0; r<4; r=r+1) begin : transform_rows
            for (c=0; c<4; c=c+1) begin : column
                wire signed [9:0] horizontal = input_transform(
                    $signed(input_tile[(4*r)*8+:8]),
                    $signed(input_tile[(4*r+1)*8+:8]),
                    $signed(input_tile[(4*r+2)*8+:8]),
                    $signed(input_tile[(4*r+3)*8+:8]), c[1:0]);
                always @(posedge clk) begin
                    if (filter_pending)
                        transformed_filter[4*r+c] <= filter_transform(
                            filter_horizontal[c], filter_horizontal[4+c],
                            filter_horizontal[8+c], r[1:0]);
                    if (state==IDLE && start_tile)
                        input_horizontal[4*r+c] <= horizontal[8:0];
                    if (state==INPUT_VERTICAL)
                        transformed_input[4*r+c] <= input_transform(
                            input_horizontal[c], input_horizontal[4+c],
                            input_horizontal[8+c], input_horizontal[12+c], r[1:0]);
                end
            end
        end
        for (c=0; c<4; c=c+1) begin : multiply_lane
            reg signed [12:0] booth_bits;
            reg signed [21:0] multiplicand, accumulator;
            wire signed [11:0] coefficient = transformed_filter[{product_row,c[1:0]}];
            wire signed [9:0] operand = transformed_input[{product_row,c[1:0]}];
            wire signed [21:0] next_sum = booth_sum(accumulator, multiplicand, booth_bits[2:0]);

            always @(posedge clk) begin
                if (state==LOAD_ROW) begin
                    booth_bits <= {coefficient,1'b0};
                    multiplicand <= {{12{operand[9]}},operand};
                    accumulator <= 0;
                end else if (state==MULTIPLY) begin
                    booth_bits <= booth_bits >>> 2;
                    multiplicand <= multiplicand <<< 2;
                    accumulator <= next_sum;
                end
            end
            for (r=0; r<4; r=r+1) begin : row_result
                always @(posedge clk)
                    if (state==MULTIPLY && digit_index==3'd5 && product_row==r[1:0])
                        products[4*r+c] <= next_sum;
            end
        end
        for (r=0; r<2; r=r+1) begin : inverse_rows
            for (c=0; c<4; c=c+1) begin : column
                wire signed [25:0] value = inverse_transform(
                    products[c], products[4+c], products[8+c], products[12+c], r[0]);
                assign vertical_sum[4*r+c] = value[23:0];
                always @(posedge clk)
                    if (state==OUTPUT_VERTICAL) output_vertical[4*r+c] <= vertical_sum[4*r+c];
            end
            for (c=0; c<2; c=c+1) begin : result_column
                assign scaled_sum[2*r+c] = inverse_transform(
                    output_vertical[4*r], output_vertical[4*r+1],
                    output_vertical[4*r+2], output_vertical[4*r+3], c[0]);
            end
        end
    endgenerate

    // Datapath registers are written before their first use in each transaction.
    // synopsys sync_set_reset "reset"
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            result_valid <= 0;
            filter_pending <= 0;
            product_row <= 0;
            digit_index <= 0;
        end else begin
            filter_pending <= load_filter;
            result_valid <= 0;
            case (state)
                IDLE: if (start_tile) state <= INPUT_VERTICAL;
                INPUT_VERTICAL: begin
                    product_row <= 0;
                    state <= LOAD_ROW;
                end
                LOAD_ROW: begin
                    digit_index <= 0;
                    state <= MULTIPLY;
                end
                MULTIPLY: begin
                    if (digit_index==3'd5) begin
                        if (product_row==2'd3) state <= OUTPUT_VERTICAL;
                        else begin
                            product_row <= product_row + 1'b1;
                            state <= LOAD_ROW;
                        end
                    end else digit_index <= digit_index + 1'b1;
                end
                OUTPUT_VERTICAL: state <= OUTPUT_HORIZONTAL;
                OUTPUT_HORIZONTAL: begin
                    // Exact divide by four. Each unscaled dot product fits in signed 19 bits.
                    tile_sums <= {scaled_sum[3][20:2],scaled_sum[2][20:2],
                                  scaled_sum[1][20:2],scaled_sum[0][20:2]};
                    result_valid <= 1;
                    state <= IDLE;
                end
                default: state <= IDLE;
            endcase
        end
    end
endmodule

