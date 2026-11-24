`timescale 1ps/1ps
// Arithmetic oracle test: all active kernels/classes, 4096 pipelined requests.
module top_tb_v28a_engine;
    reg clk=0,rst_n=0,req_valid=0,req_is_fc=0;
    reg [15:0] req_tag=0;
    reg signed [8:0] conv_tile[0:5][0:5];
    reg signed [8:0] fc_a[0:47];
    wire rsp_valid,rsp_is_fc;
    wire [15:0] rsp_tag;
    wire signed [19:0] conv_y00,conv_y01,conv_y10,conv_y11;
    wire signed [15:0] fc_sum;
    reg [403:0] stimulus[0:4095];
    reg [79:0] expected[0:4095];
    integer i,j,received=0,dummy,fd;
    string oracle_dir="./reference";
    always #5ns clk=~clk;
    pfdw_pipe49_shiftadd_engine_v28a dut(.*);
    always @(posedge clk) begin
        #1ns;
        if(rst_n && rsp_valid) begin
            if(received>=4096) $fatal(1,"Unexpected extra response");
            if(rsp_is_fc!==stimulus[received][400] || rsp_tag!==stimulus[received][399:384])
                $fatal(1,"Tag/mode mismatch vector=%0d",received);
            if(rsp_is_fc) begin
                if({{4{fc_sum[15]}},fc_sum} !== expected[received][79:60])
                    $fatal(1,"FC arithmetic mismatch vector=%0d got=%0d expected=%0d",received,$signed(fc_sum),$signed(expected[received][79:60]));
            end else if({conv_y00,conv_y01,conv_y10,conv_y11} !== expected[received])
                $fatal(1,"Conv arithmetic mismatch vector=%0d got=%h expected=%h",received,{conv_y00,conv_y01,conv_y10,conv_y11},expected[received]);
            received=received+1;
        end
    end
    initial begin
        if($value$plusargs("ORACLE_DIR=%s",oracle_dir)) $display("ORACLE_DIR=%s",oracle_dir);
        fd=$fopen({oracle_dir,"/engine_stimulus.hex"},"r");
        if(fd==0) $fatal(1,"Cannot open engine stimulus");$fclose(fd);
        fd=$fopen({oracle_dir,"/engine_expected.hex"},"r");
        if(fd==0) $fatal(1,"Cannot open engine expected outputs");$fclose(fd);
        $readmemh({oracle_dir,"/engine_stimulus.hex"},stimulus);
        $readmemh({oracle_dir,"/engine_expected.hex"},expected);
        for(j=0;j<48;j=j+1) fc_a[j]=0;
        for(j=0;j<36;j=j+1) conv_tile[j/6][j%6]=0;
        repeat(4) @(negedge clk);rst_n=1;
        for(i=0;i<4096;i=i+1) begin
            @(negedge clk);
            req_valid=1;req_is_fc=stimulus[i][400];req_tag=stimulus[i][399:384];
            for(j=0;j<48;j=j+1) fc_a[j]={1'b0,stimulus[i][(47-j)*8+:8]};
            for(j=0;j<36;j=j+1) conv_tile[j/6][j%6]={1'b0,stimulus[i][(47-j)*8+:8]};
            if(i%31==30) begin @(negedge clk);req_valid=0;end
        end
        @(negedge clk);req_valid=0;
        repeat(12) @(negedge clk);
        if(received!=4096) $fatal(1,"Missing responses %0d/4096",received);
        $display("V28A ENGINE ORACLE PASS: 4096/4096 responses; metadata and arithmetic exact");
        $finish;
    end
    initial begin #100us;$fatal(1,"ENGINE TIMEOUT");end
endmodule
