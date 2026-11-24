task unit_request;
    input write_enable;
    input [5:0] address;
    input [31:0] value;
    input integer delay_cycles;
    reg [31:0] result;
    integer count;
    begin
        @(negedge clk); u_valid=1; u_write=write_enable; u_addr=address; u_data=value; u_delay=delay_cycles;
        @(posedge clk); check32("unit_request_ready",1,u_ready);
        #1; check32("no_response_at_accept",0,u_rsp);
        @(negedge clk); u_valid=0;
        for(count=0;count<=delay_cycles;count=count+1) begin
            @(posedge clk); #1;
            check32("registered_response_latency",count==delay_cycles,u_rsp);
        end
        result=u_rdata; check32("unit_response_error",0,u_error);
        if(!write_enable) check32("unit_read_value",value,result);
        @(posedge clk); #1; check32("no_duplicate_response",0,u_rsp);
    end
endtask

task unit_memory_test;
    begin
        unit_request(1,X_BASE,32'h76543210,0);
        unit_request(0,X_BASE,32'h76543210,0);
        unit_request(0,X_BASE,32'h76543210,3);
        @(negedge clk); u_valid=1; u_write=1; u_addr=X_BASE; u_data=32'hdeadbeef; u_reset=1;
        @(posedge clk); #1; check32("reset_blocks_handshake",0,u_ready);
        @(negedge clk); u_valid=0; u_reset=0;
        unit_request(0,X_BASE,32'h76543210,0);
        @(negedge clk); u_valid=1; u_write=0; u_addr=X_BASE; u_delay=3;
        @(posedge clk); @(negedge clk); u_valid=0; u_reset=1;
        @(negedge clk); u_reset=0;
        repeat(6) begin @(posedge clk); #1; check32("reset_cancels_stale_response",0,u_rsp); end
    end
endtask
