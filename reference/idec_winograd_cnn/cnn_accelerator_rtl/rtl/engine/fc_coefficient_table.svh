// Each word contains two signed 12-bit coefficients. Class 0 is the lowest word.
// Entries in a row are printed from class 9 through class 0.
    function automatic logic [239:0] fc_coefficients(input integer lane);
        case (lane)
             0: fc_coefficients = {24'hff0_ffc, 24'h002_001, 24'hff0_002, 24'h008_004, 24'h008_002,
                                   24'h010_001, 24'hfe0_004, 24'hff8_ffc, 24'h008_001, 24'h002_001};
             1: fc_coefficients = {24'hff0_ff8, 24'h000_000, 24'hff0_ff8, 24'h010_008, 24'h008_002,
                                   24'h010_008, 24'hfe0_002, 24'hff8_000, 24'h008_004, 24'hffe_fff};
             2: fc_coefficients = {24'hff0_ffc, 24'hffc_fff, 24'hff8_ffc, 24'h008_002, 24'hff0_ffc,
                                   24'h010_004, 24'h008_fff, 24'hffc_ffe, 24'h020_fff, 24'hff8_001};
             3: fc_coefficients = {24'hffc_ffe, 24'hffc_fff, 24'h000_000, 24'h004_001, 24'hff8_001,
                                   24'h010_008, 24'h004_001, 24'hff8_001, 24'h008_001, 24'hff0_002};
             4: fc_coefficients = {24'h010_001, 24'h004_000, 24'hff0_ff8, 24'h008_001, 24'h008_001,
                                   24'h010_ffe, 24'hff0_002, 24'hff0_002, 24'hffc_000, 24'h000_000};
             5: fc_coefficients = {24'h004_000, 24'hffe_000, 24'h002_001, 24'h008_004, 24'h008_004,
                                   24'h004_002, 24'hff8_ffc, 24'hffc_000, 24'hffe_000, 24'h008_001};
             6: fc_coefficients = {24'h002_000, 24'hffc_000, 24'h008_fff, 24'hffe_fff, 24'hff0_002,
                                   24'hffe_fff, 24'hfff_000, 24'h004_000, 24'h004_000, 24'hfff_000};
             7: fc_coefficients = {24'h004_001, 24'hffc_fff, 24'h010_001, 24'hfe0_ff8, 24'hfe0_ffc,
                                   24'h004_001, 24'h008_004, 24'h008_002, 24'h004_001, 24'hffc_ffe};
             8: fc_coefficients = {24'hffc_000, 24'hff0_ffc, 24'hffe_000, 24'h008_001, 24'h000_000,
                                   24'hffe_fff, 24'h008_fff, 24'hff8_ffc, 24'hffc_000, 24'h008_004};
             9: fc_coefficients = {24'hffc_fff, 24'hfff_000, 24'h010_000, 24'h010_002, 24'h001_000,
                                   24'h004_002, 24'hff0_002, 24'hff0_001, 24'hffc_000, 24'h010_fff};
            10: fc_coefficients = {24'h004_000, 24'hffc_000, 24'hfff_000, 24'hff0_ffc, 24'h004_002,
                                   24'hff8_001, 24'hffc_fff, 24'h004_002, 24'h008_002, 24'hffe_000};
            11: fc_coefficients = {24'h010_000, 24'hffe_fff, 24'h000_000, 24'hff0_002, 24'hffe_fff,
                                   24'h004_000, 24'hff8_000, 24'h010_002, 24'h010_004, 24'h000_000};
            12: fc_coefficients = {24'hff0_002, 24'h010_002, 24'h002_001, 24'h004_000, 24'hff0_ff8,
                                   24'h002_001, 24'hff0_ffc, 24'h010_000, 24'h004_002, 24'h008_002};
            13: fc_coefficients = {24'hffc_fff, 24'hffe_fff, 24'h008_000, 24'h004_002, 24'hffc_fff,
                                   24'h004_002, 24'hfe0_004, 24'h008_002, 24'h010_001, 24'h001_000};
            14: fc_coefficients = {24'h010_ffe, 24'h000_000, 24'h010_002, 24'hffc_fff, 24'h008_002,
                                   24'h008_004, 24'hffc_000, 24'hff8_fff, 24'h008_fff, 24'hff8_fff};
            15: fc_coefficients = {24'h010_fff, 24'h002_000, 24'h008_fff, 24'h000_000, 24'h008_fff,
                                   24'h004_002, 24'h008_fff, 24'hfe0_002, 24'hff8_fff, 24'h008_fff};
            16: fc_coefficients = {24'hff0_002, 24'h008_000, 24'h004_000, 24'hffc_fff, 24'h000_000,
                                   24'hffc_ffe, 24'h002_001, 24'h010_ffe, 24'hffc_000, 24'h004_002};
            17: fc_coefficients = {24'h010_004, 24'h010_001, 24'hff0_ffe, 24'h002_001, 24'h010_002,
                                   24'h004_000, 24'h001_000, 24'hff0_002, 24'hff0_ffc, 24'hff0_fff};
            18: fc_coefficients = {24'h008_002, 24'hffe_000, 24'h004_001, 24'h002_001, 24'hffc_000,
                                   24'hff8_ffe, 24'h008_002, 24'hffc_000, 24'h004_001, 24'hff8_000};
            19: fc_coefficients = {24'h008_002, 24'hffe_000, 24'h010_008, 24'hfe0_001, 24'hff0_ffc,
                                   24'hff8_000, 24'h004_000, 24'h004_002, 24'hff0_001, 24'h010_008};
            20: fc_coefficients = {24'h010_002, 24'h002_000, 24'h002_001, 24'hff8_ffe, 24'h004_002,
                                   24'h008_002, 24'h000_000, 24'h004_002, 24'hff8_ffc, 24'hff8_ffe};
            21: fc_coefficients = {24'h010_001, 24'hffc_fff, 24'hff0_ffe, 24'hffe_000, 24'h004_001,
                                   24'h010_004, 24'hff8_000, 24'hff8_ffc, 24'hfe0_004, 24'hffe_fff};
            22: fc_coefficients = {24'hff8_ffe, 24'h008_fff, 24'hfff_000, 24'h002_000, 24'h001_000,
                                   24'h002_000, 24'h002_000, 24'hffc_000, 24'hffc_000, 24'hff8_ffe};
            23: fc_coefficients = {24'hff8_ffc, 24'hff0_ffc, 24'h010_fff, 24'h008_002, 24'h008_002,
                                   24'h010_ffe, 24'hff8_ffc, 24'h004_002, 24'h008_000, 24'hff8_ffc};
            24: fc_coefficients = {24'hffe_fff, 24'hff8_ffc, 24'hff0_ff8, 24'hffc_000, 24'h010_002,
                                   24'h000_000, 24'h008_001, 24'h010_002, 24'h004_001, 24'h002_000};
            25: fc_coefficients = {24'hff8_000, 24'h010_000, 24'hfe0_002, 24'h020_002, 24'h002_001,
                                   24'hfe0_002, 24'hfff_000, 24'h001_000, 24'hfe0_004, 24'h020_002};
            26: fc_coefficients = {24'hfe0_ff8, 24'hffc_000, 24'hffe_000, 24'h010_002, 24'hffe_fff,
                                   24'hffc_fff, 24'h004_002, 24'h010_004, 24'h020_ffc, 24'hffc_ffe};
            27: fc_coefficients = {24'h002_001, 24'h008_001, 24'hff8_ffc, 24'hff8_ffc, 24'h008_fff,
                                   24'hff8_000, 24'h010_ffe, 24'h004_001, 24'hffc_000, 24'hff8_ffc};
            28: fc_coefficients = {24'h004_001, 24'h004_000, 24'h008_002, 24'hfe0_fff, 24'h004_002,
                                   24'hff8_ffe, 24'h010_008, 24'hfff_000, 24'hff8_ffe, 24'hff8_fff};
            29: fc_coefficients = {24'h000_000, 24'h010_004, 24'hff0_001, 24'hffc_ffe, 24'h008_000,
                                   24'hff0_ff8, 24'h004_002, 24'h004_000, 24'hff8_fff, 24'h008_001};
            30: fc_coefficients = {24'hffe_000, 24'h001_000, 24'h008_001, 24'hff0_002, 24'h008_002,
                                   24'hffe_000, 24'h004_001, 24'h004_001, 24'hff8_001, 24'hffe_000};
            31: fc_coefficients = {24'h004_001, 24'h004_001, 24'hffe_000, 24'hff0_001, 24'h004_001,
                                   24'hffe_000, 24'h002_000, 24'h010_fff, 24'h010_002, 24'hff0_ffe};
            32: fc_coefficients = {24'h010_008, 24'h008_004, 24'hff8_000, 24'h008_000, 24'h002_001,
                                   24'h000_000, 24'hff0_000, 24'hff8_ffc, 24'hff0_fff, 24'h008_002};
            33: fc_coefficients = {24'hff8_000, 24'hffc_fff, 24'hff0_000, 24'h008_001, 24'h002_001,
                                   24'hffe_000, 24'hff8_fff, 24'hff0_002, 24'h008_fff, 24'hffe_fff};
            34: fc_coefficients = {24'hff8_fff, 24'hff0_002, 24'h008_002, 24'h008_004, 24'hff8_001,
                                   24'h008_001, 24'hff8_ffe, 24'hff0_ff8, 24'h008_004, 24'h001_000};
            35: fc_coefficients = {24'hff0_ffc, 24'hff8_001, 24'h010_008, 24'hff8_ffe, 24'h010_008,
                                   24'h010_004, 24'h000_000, 24'hff0_ff8, 24'h008_002, 24'hff8_000};
            36: fc_coefficients = {24'hff8_000, 24'hff8_ffc, 24'hff0_001, 24'h004_001, 24'h000_000,
                                   24'h002_000, 24'hffe_000, 24'h000_000, 24'hffe_000, 24'h008_000};
            37: fc_coefficients = {24'h004_000, 24'hffc_fff, 24'hffc_ffe, 24'h004_000, 24'hffe_fff,
                                   24'hff0_001, 24'h010_008, 24'hffe_000, 24'hffe_000, 24'h004_001};
            38: fc_coefficients = {24'h008_002, 24'h010_fff, 24'hffc_000, 24'hff8_000, 24'hfe0_ffc,
                                   24'h002_001, 24'h008_004, 24'h008_002, 24'h008_004, 24'hff0_001};
            39: fc_coefficients = {24'h001_000, 24'h008_fff, 24'h004_002, 24'hffc_fff, 24'hff0_ffe,
                                   24'hffe_000, 24'hff8_ffc, 24'h004_002, 24'hff8_001, 24'hffc_000};
            40: fc_coefficients = {24'hfe0_004, 24'h010_002, 24'h010_fff, 24'h001_000, 24'hff8_ffc,
                                   24'hff8_001, 24'h001_000, 24'h020_fff, 24'h008_fff, 24'h008_fff};
            41: fc_coefficients = {24'hff0_ffc, 24'h002_001, 24'h010_004, 24'hfff_000, 24'hff0_002,
                                   24'hff0_ff8, 24'hffc_000, 24'h008_002, 24'h004_000, 24'hff0_ffc};
            42: fc_coefficients = {24'h004_000, 24'hff0_fff, 24'h008_004, 24'hff8_ffc, 24'hff0_fff,
                                   24'hffe_fff, 24'hff8_000, 24'h008_004, 24'hff8_ffe, 24'h008_fff};
            43: fc_coefficients = {24'h004_002, 24'hff0_001, 24'h010_ffe, 24'h002_001, 24'hff0_ffc,
                                   24'hff8_ffe, 24'hff8_001, 24'h008_001, 24'hff8_ffc, 24'h010_002};
            44: fc_coefficients = {24'hffc_000, 24'h004_000, 24'h008_fff, 24'h001_000, 24'h000_000,
                                   24'h004_001, 24'hff8_fff, 24'h001_000, 24'h008_002, 24'h000_000};
            45: fc_coefficients = {24'hffe_000, 24'hff0_001, 24'h000_000, 24'hff0_ffc, 24'h010_fff,
                                   24'h000_000, 24'h000_000, 24'hff8_000, 24'hffc_ffe, 24'hff8_ffc};
            46: fc_coefficients = {24'h004_001, 24'hffe_fff, 24'h008_002, 24'hffe_fff, 24'h010_000,
                                   24'hff8_ffc, 24'h010_008, 24'hff0_002, 24'h002_000, 24'hffc_ffe};
            47: fc_coefficients = {24'hffc_000, 24'hffe_000, 24'hff8_ffc, 24'h002_001, 24'h008_fff,
                                   24'hff8_001, 24'h002_000, 24'hff8_ffc, 24'hffc_000, 24'h004_002};
            48: fc_coefficients = {24'h000_000, 24'h000_000, 24'h000_000, 24'h000_000, 24'h000_000,
                                   24'h000_000, 24'h000_000, 24'h000_000, 24'h000_000, 24'h000_000};
            default: fc_coefficients = '0;
        endcase
    endfunction
