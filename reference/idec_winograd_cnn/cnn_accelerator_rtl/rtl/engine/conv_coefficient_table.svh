// Fixed model W477_A88_Cpot1-pot1-sp2_T32-0-0_M67.
// Each word contains two signed 12-bit coefficients. The lowest word is entry 0.
// Conv1 entries are physical output channels 0, 1 in ascending order.
    function automatic logic [47:0] conv1_coefficients(input integer lane);
        case (lane)
             0: conv1_coefficients = {24'h000_000, 24'h000_000};
             1: conv1_coefficients = {24'h000_000, 24'h004_000};
             2: conv1_coefficients = {24'h000_000, 24'h004_000};
             3: conv1_coefficients = {24'h000_000, 24'h008_000};
             4: conv1_coefficients = {24'h004_000, 24'hffc_000};
             5: conv1_coefficients = {24'h004_000, 24'h000_000};
             6: conv1_coefficients = {24'h000_000, 24'h004_000};
             7: conv1_coefficients = {24'h000_000, 24'h008_000};
             8: conv1_coefficients = {24'hffc_000, 24'hffc_000};
             9: conv1_coefficients = {24'hffc_000, 24'h004_000};
            10: conv1_coefficients = {24'h000_000, 24'h000_000};
            11: conv1_coefficients = {24'h000_000, 24'h008_000};
            12: conv1_coefficients = {24'h000_000, 24'hff8_000};
            13: conv1_coefficients = {24'h000_000, 24'h000_000};
            14: conv1_coefficients = {24'h000_000, 24'h000_000};
            15: conv1_coefficients = {24'h000_000, 24'h008_000};
            16: conv1_coefficients = {24'h000_000, 24'h008_000};
            17: conv1_coefficients = {24'h000_000, 24'h010_000};
            18: conv1_coefficients = {24'h000_000, 24'h008_000};
            19: conv1_coefficients = {24'hffc_000, 24'h010_000};
            20: conv1_coefficients = {24'hff8_000, 24'h020_000};
            21: conv1_coefficients = {24'hffc_000, 24'h008_000};
            22: conv1_coefficients = {24'h004_000, 24'h004_000};
            23: conv1_coefficients = {24'h008_000, 24'h008_000};
            24: conv1_coefficients = {24'h004_000, 24'h002_000};
            25: conv1_coefficients = {24'h000_000, 24'h008_000};
            26: conv1_coefficients = {24'h000_000, 24'h010_000};
            27: conv1_coefficients = {24'h000_000, 24'h004_000};
            28: conv1_coefficients = {24'h000_000, 24'h000_000};
            29: conv1_coefficients = {24'h002_000, 24'h002_000};
            30: conv1_coefficients = {24'h002_000, 24'h002_000};
            31: conv1_coefficients = {24'h004_000, 24'h004_000};
            32: conv1_coefficients = {24'h000_000, 24'h000_000};
            33: conv1_coefficients = {24'h008_000, 24'h004_000};
            34: conv1_coefficients = {24'h004_000, 24'h004_000};
            35: conv1_coefficients = {24'h010_000, 24'h008_000};
            36: conv1_coefficients = {24'h000_000, 24'h000_000};
            37: conv1_coefficients = {24'h008_000, 24'h002_000};
            38: conv1_coefficients = {24'h001_000, 24'h002_000};
            39: conv1_coefficients = {24'h008_000, 24'h004_000};
            40: conv1_coefficients = {24'h004_000, 24'h004_000};
            41: conv1_coefficients = {24'h008_000, 24'h004_000};
            42: conv1_coefficients = {24'h002_000, 24'h000_000};
            43: conv1_coefficients = {24'h008_000, 24'h008_000};
            44: conv1_coefficients = {24'h010_000, 24'h008_000};
            45: conv1_coefficients = {24'h004_000, 24'h002_000};
            46: conv1_coefficients = {24'h004_000, 24'h002_000};
            47: conv1_coefficients = {24'h008_000, 24'h004_000};
            48: conv1_coefficients = {24'h002_000, 24'h002_000};
            default: conv1_coefficients = '0;
        endcase
    endfunction

// Conv2 entries are (output, input): (0,0), (0,1), (1,0), (1,1), (2,0), (2,1).
    function automatic logic [143:0] conv2_coefficients(input integer lane);
        case (lane)
             0: conv2_coefficients = {24'hfe0_000, 24'hfe0_000, 24'hfe0_000, 24'hfc0_000, 24'hff8_000, 24'h080_000};
             1: conv2_coefficients = {24'hfc0_000, 24'hffc_000, 24'hfc0_000, 24'hfc0_000, 24'hfc0_000, 24'h040_000};
             2: conv2_coefficients = {24'hff0_000, 24'hff0_000, 24'hfe0_000, 24'hff8_000, 24'hfc0_000, 24'h020_000};
             3: conv2_coefficients = {24'hfc0_000, 24'h008_000, 24'hfe0_000, 24'hfe0_000, 24'hf80_000, 24'hff0_000};
             4: conv2_coefficients = {24'hfc0_000, 24'hfc0_000, 24'h004_000, 24'hff8_000, 24'hfc0_000, 24'h080_000};
             5: conv2_coefficients = {24'hfc0_000, 24'hfc0_000, 24'h010_000, 24'hfc0_000, 24'hf80_000, 24'h040_000};
             6: conv2_coefficients = {24'h001_000, 24'hff8_000, 24'hff0_000, 24'h008_000, 24'hfe0_000, 24'hff0_000};
             7: conv2_coefficients = {24'hff0_000, 24'hfe0_000, 24'hffc_000, 24'hfe0_000, 24'hf80_000, 24'hfc0_000};
             8: conv2_coefficients = {24'hff8_000, 24'hff0_000, 24'hfe0_000, 24'hff0_000, 24'hff8_000, 24'h040_000};
             9: conv2_coefficients = {24'hff0_000, 24'h040_000, 24'hff0_000, 24'hfe0_000, 24'hff8_000, 24'h010_000};
            10: conv2_coefficients = {24'hff0_000, 24'h020_000, 24'hff0_000, 24'hffc_000, 24'h001_000, 24'h020_000};
            11: conv2_coefficients = {24'hfe0_000, 24'h040_000, 24'h008_000, 24'hff0_000, 24'h002_000, 24'hff0_000};
            12: conv2_coefficients = {24'hff0_000, 24'hfe0_000, 24'h004_000, 24'h020_000, 24'hfc0_000, 24'h080_000};
            13: conv2_coefficients = {24'hff0_000, 24'hff0_000, 24'h040_000, 24'hffc_000, 24'hfc0_000, 24'h040_000};
            14: conv2_coefficients = {24'h008_000, 24'h020_000, 24'h002_000, 24'h010_000, 24'h008_000, 24'hff8_000};
            15: conv2_coefficients = {24'h004_000, 24'h020_000, 24'h020_000, 24'hfe0_000, 24'hffc_000, 24'hf80_000};
            16: conv2_coefficients = {24'hfe0_000, 24'hff0_000, 24'h000_000, 24'hff0_000, 24'hfc0_000, 24'hfc0_000};
            17: conv2_coefficients = {24'hff0_000, 24'hffe_000, 24'h020_000, 24'hff8_000, 24'hfc0_000, 24'hfc0_000};
            18: conv2_coefficients = {24'h010_000, 24'h008_000, 24'h020_000, 24'h008_000, 24'hff0_000, 24'hff0_000};
            19: conv2_coefficients = {24'hff8_000, 24'h010_000, 24'h010_000, 24'hff8_000, 24'hfc0_000, 24'hfc0_000};
            20: conv2_coefficients = {24'hff0_000, 24'h040_000, 24'h040_000, 24'hfe0_000, 24'hfc0_000, 24'hfe0_000};
            21: conv2_coefficients = {24'hff8_000, 24'h040_000, 24'h020_000, 24'hff0_000, 24'hff0_000, 24'h020_000};
            22: conv2_coefficients = {24'hff0_000, 24'h010_000, 24'hff8_000, 24'hff0_000, 24'hfe0_000, 24'hff8_000};
            23: conv2_coefficients = {24'hfe0_000, 24'h010_000, 24'hff8_000, 24'hfe0_000, 24'hfc0_000, 24'hff0_000};
            24: conv2_coefficients = {24'hff8_000, 24'h002_000, 24'hffe_000, 24'hff8_000, 24'hff0_000, 24'hff8_000};
            25: conv2_coefficients = {24'h004_000, 24'h040_000, 24'h010_000, 24'hff0_000, 24'hfe0_000, 24'hff0_000};
            26: conv2_coefficients = {24'hfe0_000, 24'h080_000, 24'h010_000, 24'hfc0_000, 24'hfc0_000, 24'h020_000};
            27: conv2_coefficients = {24'hfe0_000, 24'h020_000, 24'h008_000, 24'hfe0_000, 24'hfe0_000, 24'h040_000};
            28: conv2_coefficients = {24'hffe_000, 24'h010_000, 24'hff8_000, 24'h008_000, 24'hfe0_000, 24'h040_000};
            29: conv2_coefficients = {24'hff8_000, 24'h020_000, 24'h020_000, 24'hffc_000, 24'hff0_000, 24'h010_000};
            30: conv2_coefficients = {24'hff8_000, 24'h020_000, 24'h002_000, 24'hfe0_000, 24'hff0_000, 24'h010_000};
            31: conv2_coefficients = {24'hff0_000, 24'h040_000, 24'h020_000, 24'hfe0_000, 24'hffc_000, 24'hff0_000};
            32: conv2_coefficients = {24'hff0_000, 24'h010_000, 24'hfe0_000, 24'h000_000, 24'hfc0_000, 24'h040_000};
            33: conv2_coefficients = {24'hfe0_000, 24'h040_000, 24'h040_000, 24'h010_000, 24'hff0_000, 24'h020_000};
            34: conv2_coefficients = {24'hff0_000, 24'h020_000, 24'h004_000, 24'hfe0_000, 24'hfe0_000, 24'h020_000};
            35: conv2_coefficients = {24'hfe0_000, 24'h040_000, 24'h080_000, 24'hff0_000, 24'h004_000, 24'h002_000};
            36: conv2_coefficients = {24'hff8_000, 24'h002_000, 24'hff0_000, 24'hff8_000, 24'hfe0_000, 24'h008_000};
            37: conv2_coefficients = {24'hff0_000, 24'h020_000, 24'h040_000, 24'h010_000, 24'h004_000, 24'h010_000};
            38: conv2_coefficients = {24'hff8_000, 24'hfff_000, 24'h002_000, 24'hff8_000, 24'hff0_000, 24'h010_000};
            39: conv2_coefficients = {24'hff0_000, 24'h020_000, 24'h040_000, 24'h010_000, 24'h008_000, 24'h010_000};
            40: conv2_coefficients = {24'hff8_000, 24'h010_000, 24'h010_000, 24'hff0_000, 24'hff0_000, 24'hff8_000};
            41: conv2_coefficients = {24'hff0_000, 24'h008_000, 24'h020_000, 24'hff0_000, 24'hff0_000, 24'h001_000};
            42: conv2_coefficients = {24'hffe_000, 24'hff8_000, 24'h008_000, 24'hffc_000, 24'hffc_000, 24'h008_000};
            43: conv2_coefficients = {24'hffe_000, 24'h010_000, 24'h020_000, 24'h008_000, 24'hff0_000, 24'hff8_000};
            44: conv2_coefficients = {24'hffc_000, 24'h010_000, 24'h040_000, 24'h010_000, 24'hff0_000, 24'h010_000};
            45: conv2_coefficients = {24'hfff_000, 24'hffc_000, 24'h010_000, 24'h008_000, 24'hfff_000, 24'h020_000};
            46: conv2_coefficients = {24'h008_000, 24'h004_000, 24'h020_000, 24'h010_000, 24'hffe_000, 24'h001_000};
            47: conv2_coefficients = {24'h008_000, 24'h008_000, 24'h020_000, 24'h020_000, 24'h000_000, 24'h010_000};
            48: conv2_coefficients = {24'h002_000, 24'h002_000, 24'h004_000, 24'h008_000, 24'h002_000, 24'h010_000};
            default: conv2_coefficients = '0;
        endcase
    endfunction
