    // Observe the response consumed by the controller, BEFORE NBA.
    always @(posedge clk) begin
        if(rst_n) begin
            if(dut.u_inference_core.req_valid) begin
                if(dut.u_inference_core.req_is_fc) fc_requests=fc_requests+1;
                else if(dut.u_inference_core.req_tag[15]) c2_requests=c2_requests+1;
                else c1_requests=c1_requests+1;
            end
            if(dut.u_inference_core.rsp_valid && dut.u_inference_core.rsp_is_fc && !random_mode && !no_oracle) begin
                if(dut.u_inference_core.fc_score_now !== golden_scores[sample_idx*10+dut.u_inference_core.rsp_fc_class])
                    $fatal(1,"FC score mismatch image=%0d class=%0d RTL=%0d golden=%0d",sample_idx,dut.u_inference_core.rsp_fc_class,$signed(dut.u_inference_core.fc_score_now),$signed(golden_scores[sample_idx*10+dut.u_inference_core.rsp_fc_class]));
                fc_scores_checked=fc_scores_checked+1;
            end
        end
    end
    // Observe after NBA, independently of stream-driving task.
    always @(posedge clk) begin
        #1ns;
        if(rst_n && valid_out_6) begin
            if(seen) $fatal(1,"Duplicate completion for image %0d",sample_idx);
            if($isunknown(decision) || decision>9) $fatal(1,"Invalid class decision");
            seen=1; result=decision; done_cycle=cycle_no;
        end
    end
