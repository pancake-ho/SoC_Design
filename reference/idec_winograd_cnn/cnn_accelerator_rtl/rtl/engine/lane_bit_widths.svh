    // Lane-specific activation and product widths from the original RTL.
    function automatic logic [15:0] lane_widths(input integer lane);
        case (lane)
            34, 41, 43, 45, 47: lane_widths = {8'd9, 8'd14};
            17, 23, 32, 44: lane_widths = {8'd9, 8'd15};
            26, 35: lane_widths = {8'd9, 8'd16};
            24, 40, 42, 48: lane_widths = {8'd10, 8'd14};
            6, 10, 14, 18, 22, 29, 30, 36, 38, 46: lane_widths = {8'd10, 8'd15};
            1, 2, 8, 9, 11, 13, 16, 19, 20, 21, 25, 27, 28, 31, 33, 37, 39: lane_widths = {8'd10, 8'd16};
            0, 3, 4, 7, 12, 15: lane_widths = {8'd10, 8'd17};
            5: lane_widths = {8'd11, 8'd18};
            default: lane_widths = {8'd11, 8'd18};
        endcase
    endfunction
