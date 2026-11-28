    localparam F12_RESULT_COUNT=2*OUT_WORDS;
    localparam F12_GOLDEN_START=2+X_WORDS+W_WORDS+BIAS_WORDS;
    integer f12_first_address_pc, f12_next_address_pc, f12_address_store_pc, f12_lw_pc;
    integer f12_lw_count=0, f12_phase=0;
    longint f12_first_lw_ps=-1, f12_last_lw_ps=-1;

    task require_f12_readback_pcs;
        begin
            if (!$value$plusargs("F12_ADDR_FIRST_PC=%d",f12_first_address_pc) ||
                !$value$plusargs("F12_ADDR_NEXT_PC=%d",f12_next_address_pc) ||
                !$value$plusargs("F12_ADDR_STORE_PC=%d",f12_address_store_pc) ||
                !$value$plusargs("F12_LW_PC=%d",f12_lw_pc))
                $fatal(1,"F12 readback program checkpoints required");
        end
    endtask

    // The driver uses the common MMIO protocol. These observations are only
    // architectural instruction retirements at the project_top boundary.
    task check_f12_readback_commit;
        reg [31:0] expected_address, expected_word;
        begin
            expected_address=4*(RAW_BASE+f12_lw_count);
            if (commit_pc==f12_first_address_pc || commit_pc==f12_next_address_pc) begin
                check32("f12_pointer_order",1,f12_phase==0 &&
                    ((f12_lw_count==0 && commit_pc==f12_first_address_pc) ||
                     (f12_lw_count>0 && commit_pc==f12_next_address_pc)));
                check32("f12_pointer_instruction",program_words[commit_pc>>2],commit_insn);
                check32("f12_pointer_rd",1,{27'b0,commit_rd});
                check32("f12_pointer_address",expected_address,commit_wdata);
                if (f12_lw_count<F12_RESULT_COUNT) f12_phase=1;
            end else if (commit_pc==f12_address_store_pc) begin
                check32("f12_address_store_order",1,f12_phase==1 &&
                    cnn_done_ps>=0 && reserved_out[2:0]===3'b010);
                check32("f12_address_store_instruction",program_words[commit_pc>>2],commit_insn);
                f12_phase=2;
            end else if (commit_pc==f12_lw_pc) begin
                check32("f12_lw_order",1,f12_phase==2);
                check32("f12_lw_after_done",1,cnn_done_ps>=0 &&
                    now_ps()>cnn_done_ps && reserved_out[2:0]===3'b010);
                check32("f12_lw_instruction",program_words[commit_pc>>2],commit_insn);
                check32("f12_lw_rd",2,{27'b0,commit_rd});
                if (f12_lw_count<F12_RESULT_COUNT) begin
                    expected_word=vectors[F12_GOLDEN_START+f12_lw_count];
                    if (commit_wdata!==expected_word)
                        $display("F12_LW_MISMATCH index=%0d address=%08h expected=%08h actual=%08h",
                            f12_lw_count,expected_address,expected_word,commit_wdata);
                    check32("f12_lw_word",expected_word,commit_wdata);
                end else check32("f12_extra_lw",0,1);
                if (f12_lw_count==0) f12_first_lw_ps=now_ps();
                f12_last_lw_ps=now_ps();
                f12_lw_count=f12_lw_count+1;
                f12_phase=0;
            end
        end
    endtask
