`timescale 1ps/1ps
// Fixed-model CNN inference test with up to 1000 images.
// +DATA_DIR=<data folder> +ORACLE_DIR=<reference folder> +NUM_IMAGES=<count>
// Expected project checkpoint: 990/1000 = 99.00%.
// Trained weight input ports are still driven for interface compatibility, but
// The CNN uses embedded transform-domain coefficients.
module tb_cnn_inference;
    localparam MAX_IMAGES=1000;
    reg clk=0,rst_n=0;
    reg [7:0] data_in=0;
    reg [7:0] pixels[0:783999];
    reg [7:0] labels[0:999];
    wire [3:0] decision;
    wire valid_out_6;
    integer sample_idx,pixel_idx,cycle_no,done_cycle,correct=0;
    integer min_cycles=2147483647,max_cycles=0,total_cycles=0,num_images=1000;
    integer random_mode,have_labels,fd;
    reg seen=0;
    reg [3:0] result;
    reg [31:0] rng=32'h2468ace1;
    string data_dir="./data",label_file;
    string oracle_dir="./reference";
    integer no_oracle,oracle_matches=0,fc_scores_checked=0;
    integer c1_requests=0,c2_requests=0,fc_requests=0;
    reg [3:0] golden_predictions[0:MAX_IMAGES-1];
    reg [11:0] golden_scores[0:MAX_IMAGES*10-1];
    always #5ns clk=~clk;
    function automatic [31:0] rand32();
        begin rng=rng^(rng<<13);rng=rng^(rng>>17);rng=rng^(rng<<5);rand32=rng;end
    endfunction
    task automatic require_file(input string name);
        begin fd=$fopen(name,"r");if(fd==0)$fatal(1,"Cannot open %s",name);$fclose(fd);end
    endtask

    `include "cnn_test_weights.svh"

    cnn_accelerator_top dut(.clk(clk),.rst_n(rst_n),.data_in(data_in),
        .decision(decision),.valid_out_6(valid_out_6),
        .w_11(w_11),.w_12(w_12),.w_13(w_13),.b_1(b_1),.b_2(b_2),
        .w_211(w_211),.w_212(w_212),.w_213(w_213),
        .w_221(w_221),.w_222(w_222),.w_223(w_223),
        .w_231(w_231),.w_232(w_232),.w_233(w_233),
        .w_fc(w_fc),.b_fc(b_fc));

    `include "cnn_test_scoreboard.svh"

    initial begin
        if($value$plusargs("DATA_DIR=%s",data_dir)) $display("DATA_DIR=%s",data_dir);
        if($value$plusargs("ORACLE_DIR=%s",oracle_dir)) $display("ORACLE_DIR=%s",oracle_dir);
        no_oracle=$test$plusargs("NO_ORACLE");
        if($value$plusargs("NUM_IMAGES=%d",num_images)) $display("NUM_IMAGES=%d",num_images);
        random_mode=$test$plusargs("RANDOM");
        have_labels=$value$plusargs("LABEL_FILE=%s",label_file);
        if(num_images<1 || num_images>1000) $fatal(1,"NUM_IMAGES must be 1..1000");
        
        if(!random_mode) begin
            require_file({data_dir,"/input_1000.txt"});
            $readmemh({data_dir,"/input_1000.txt"}, pixels);
            require_file({data_dir,"/conv1_weight_1.txt"});
            $readmemh({data_dir,"/conv1_weight_1.txt"}, weight_11);
            require_file({data_dir,"/conv1_weight_2.txt"});
            $readmemh({data_dir,"/conv1_weight_2.txt"}, weight_12);
            require_file({data_dir,"/conv1_weight_3.txt"});
            $readmemh({data_dir,"/conv1_weight_3.txt"}, weight_13);
            require_file({data_dir,"/conv1_bias.txt"});
            $readmemh({data_dir,"/conv1_bias.txt"}, bias_1);
            require_file({data_dir,"/conv2_bias.txt"});
            $readmemh({data_dir,"/conv2_bias.txt"}, bias_2);
            require_file({data_dir,"/conv2_weight_11.txt"});
            $readmemh({data_dir,"/conv2_weight_11.txt"}, weight_211);
            require_file({data_dir,"/conv2_weight_12.txt"});
            $readmemh({data_dir,"/conv2_weight_12.txt"}, weight_212);
            require_file({data_dir,"/conv2_weight_13.txt"});
            $readmemh({data_dir,"/conv2_weight_13.txt"}, weight_213);
            require_file({data_dir,"/conv2_weight_21.txt"});
            $readmemh({data_dir,"/conv2_weight_21.txt"}, weight_221);
            require_file({data_dir,"/conv2_weight_22.txt"});
            $readmemh({data_dir,"/conv2_weight_22.txt"}, weight_222);
            require_file({data_dir,"/conv2_weight_23.txt"});
            $readmemh({data_dir,"/conv2_weight_23.txt"}, weight_223);
            require_file({data_dir,"/conv2_weight_31.txt"});
            $readmemh({data_dir,"/conv2_weight_31.txt"}, weight_231);
            require_file({data_dir,"/conv2_weight_32.txt"});
            $readmemh({data_dir,"/conv2_weight_32.txt"}, weight_232);
            require_file({data_dir,"/conv2_weight_33.txt"});
            $readmemh({data_dir,"/conv2_weight_33.txt"}, weight_233);
            require_file({data_dir,"/fc_weight.txt"});
            $readmemh({data_dir,"/fc_weight.txt"}, weight_fc);
            require_file({data_dir,"/fc_bias.txt"});
            $readmemh({data_dir,"/fc_bias.txt"}, bias_fc);
            if(have_labels) begin
                require_file(label_file);$readmemh(label_file,labels);
            end
            for(integer i=0;i<num_images*784;i=i+1)
                if($isunknown(pixels[i])) $fatal(1,"Missing/unknown pixel %0d",i);
            if(have_labels) for(integer i=0;i<num_images;i=i+1)
                if($isunknown(labels[i]) || labels[i]>9) $fatal(1,"Invalid label %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_11[i])) $fatal(1,"Missing weight_11 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_12[i])) $fatal(1,"Missing weight_12 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_13[i])) $fatal(1,"Missing weight_13 %0d",i);
            for(integer i=0;i<3;i=i+1) if($isunknown(bias_1[i])) $fatal(1,"Missing bias_1 %0d",i);
            for(integer i=0;i<3;i=i+1) if($isunknown(bias_2[i])) $fatal(1,"Missing bias_2 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_211[i])) $fatal(1,"Missing weight_211 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_212[i])) $fatal(1,"Missing weight_212 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_213[i])) $fatal(1,"Missing weight_213 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_221[i])) $fatal(1,"Missing weight_221 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_222[i])) $fatal(1,"Missing weight_222 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_223[i])) $fatal(1,"Missing weight_223 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_231[i])) $fatal(1,"Missing weight_231 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_232[i])) $fatal(1,"Missing weight_232 %0d",i);
            for(integer i=0;i<25;i=i+1) if($isunknown(weight_233[i])) $fatal(1,"Missing weight_233 %0d",i);
            for(integer i=0;i<480;i=i+1) if($isunknown(weight_fc[i])) $fatal(1,"Missing weight_fc %0d",i);
            for(integer i=0;i<10;i=i+1) if($isunknown(bias_fc[i])) $fatal(1,"Missing bias_fc %0d",i);
        end
        if(!random_mode && !no_oracle) begin
            require_file({oracle_dir,"/predictions_1000.hex"});
            require_file({oracle_dir,"/scores_1000.hex"});
            $readmemh({oracle_dir,"/predictions_1000.hex"},golden_predictions);
            $readmemh({oracle_dir,"/scores_1000.hex"},golden_scores);
        end
        for(sample_idx=0;sample_idx<num_images;sample_idx=sample_idx+1) begin
            @(negedge clk);rst_n=0;data_in=0;
            repeat(3) @(negedge clk);
            seen=0;cycle_no=0;done_cycle=0;
            c1_requests=0;c2_requests=0;fc_requests=0;
            if(random_mode) begin
                for(integer i=0;i<25;i=i+1) weight_11[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_12[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_13[i]=rand32();
                for(integer i=0;i<3;i=i+1) bias_1[i]=rand32();
                for(integer i=0;i<3;i=i+1) bias_2[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_211[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_212[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_213[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_221[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_222[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_223[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_231[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_232[i]=rand32();
                for(integer i=0;i<25;i=i+1) weight_233[i]=rand32();
                for(integer i=0;i<480;i=i+1) weight_fc[i]=rand32();
                for(integer i=0;i<10;i=i+1) bias_fc[i]=rand32();
                for(integer i=0;i<784;i=i+1)
                    case(sample_idx%4)
                        0:pixels[sample_idx*784+i]=0;
                        1:pixels[sample_idx*784+i]=255;
                        2:pixels[sample_idx*784+i]=(i%2)?255:0;
                        default:pixels[sample_idx*784+i]=rand32();
                    endcase
            end
            rst_n=1; // one explicit priming edge before pixel[0]
            @(negedge clk);
            for(pixel_idx=0;pixel_idx<784;pixel_idx=pixel_idx+1) begin
                data_in=pixels[sample_idx*784+pixel_idx];
                cycle_no=pixel_idx+1; // first captured pixel is inclusive cycle 1
                @(negedge clk);
            end
            data_in=0;
            while(!seen && cycle_no<2000) begin
                cycle_no=cycle_no+1;
                @(negedge clk);
            end
            if(!seen) $fatal(1,"Inference timeout for image %0d",sample_idx);
            if (done_cycle != 836)
                $fatal(1, "Cycle mismatch image=%0d got=%0d expected=836", sample_idx, done_cycle);
            if(c1_requests!=288 || c2_requests!=96 || fc_requests!=10)
                $fatal(1,"Request count mismatch C1=%0d C2=%0d FC=%0d",c1_requests,c2_requests,fc_requests);
            if(!random_mode && !no_oracle) begin
                if(result !== golden_predictions[sample_idx])
                    $fatal(1,"PYTHON/RTL mismatch image=%0d RTL=%0d golden=%0d",sample_idx,result,golden_predictions[sample_idx]);
                oracle_matches=oracle_matches+1;
            end
            if(!random_mode && result==(have_labels?labels[sample_idx]:(sample_idx%10))) correct=correct+1;
            if(done_cycle<min_cycles) min_cycles=done_cycle;
            if(done_cycle>max_cycles) max_cycles=done_cycle;
            total_cycles=total_cycles+done_cycle;
            if(sample_idx==0 || (sample_idx+1)%100==0)
                $display("image=%0d decision=%0d inclusive_cycles=%0d",sample_idx,result,done_cycle);
            // Check that completion is a single pulse and no extra outputs follow.
            repeat(12) @(negedge clk);
        end
        $display("CNN INFERENCE COMPLETE: images=%0d inclusive_cycles_min=%0d max=%0d avg=%0.3f",num_images,min_cycles,max_cycles,1.0*total_cycles/num_images);
        $display("ELAPSED CYCLES: min=%0d max=%0d avg=%0.3f",min_cycles-1,max_cycles-1,1.0*total_cycles/num_images-1);
        $display("Cycle convention: pixel[0] capture=1; elapsed edge intervals=inclusive_cycles-1.");
        if(random_mode) $display("SYNTHETIC ONLY: no dataset accuracy claim");
        else $display("ACCURACY: %0d/%0d (%0.2f%%), labels=%s",correct,num_images,100.0*correct/num_images,have_labels?"file":"index modulo 10");
        if(!random_mode && !have_labels && num_images==1000) begin
            if(correct != 990)
                $fatal(1,"Accuracy checkpoint mismatch: expected 990/1000, got %0d/1000",correct);
            else
                $display("ACCURACY CHECKPOINT PASS: 990/1000 (99.00%%)");
        end
        if(!random_mode && !no_oracle) begin
            if(oracle_matches!=num_images || fc_scores_checked!=num_images*10)
                $fatal(1,"Oracle coverage incomplete predictions=%0d scores=%0d",oracle_matches,fc_scores_checked);
            $display("PYTHON ORACLE PASS: predictions=%0d FC scores=%0d",oracle_matches,fc_scores_checked);
        end
        $finish;
    end
    initial begin #100ms;$fatal(1,"GLOBAL TIMEOUT");end
endmodule
