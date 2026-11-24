    `ifndef EE470_ABS_DELAY_PS
    `define EE470_ABS_DELAY_PS 0
    `endif
    localparam integer checkpoint_injected_ps=`EE470_ABS_DELAY_PS;
    wire checkpoint_done;
    assign #(checkpoint_injected_ps/1000.0) checkpoint_done=reserved_out[1];

    longint clk_edge_ps=0;
    longint cnn_busy_ps=-1, cnn_done_ps=-1;
    longint cnn_busy_clk_ps=-1, cnn_done_clk_ps=-1;
    integer cnn_busy_cycle=-1, cnn_done_cycle=-1;

    function automatic longint now_ps;
        now_ps = longint'($realtime * 1000.0);
    endfunction

    // BUSY/DONE are contract output pins; capture pin transitions at 1 ps resolution.
    always @(posedge reserved_out[0])
        if(rst_n && case_name=="F12" && reserved_out[0]===1'b1 && cnn_busy_ps<0) begin
            cnn_busy_ps=now_ps();
            cnn_busy_clk_ps=clk_edge_ps;
            cnn_busy_cycle=cycle_count;
        end
    always @(posedge checkpoint_done)
        if(rst_n && case_name=="F12" && checkpoint_done===1'b1 && cnn_busy_ps>=0 && cnn_done_ps<0) begin
            cnn_done_ps=now_ps();
            cnn_done_clk_ps=clk_edge_ps;
            cnn_done_cycle=cycle_count;
        end
