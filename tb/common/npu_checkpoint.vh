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
    integer cnn_done_rises=0;
    reg measure_next_reset=0;
    longint workload_reset_ps=-1, workload_first_clk_ps=-1;
    longint workload_load_complete_ps=-1;

    function automatic longint now_ps;
        now_ps = longint'($realtime * 1000.0);
    endfunction

    // Start the timed workload after fixture loading and the measured reset.
    always @(posedge rst_n)
        if(case_name=="F12" && measure_next_reset && workload_reset_ps<0)
            workload_reset_ps=now_ps();

    always @(posedge clk)
        if(rst_n && workload_reset_ps>=0 && workload_first_clk_ps<0)
            workload_first_clk_ps=now_ps();

    // BUSY/DONE are contract output pins; capture pin transitions at 1 ps resolution.
    always @(posedge reserved_out[0])
        if(rst_n && busy===1'b1 && workload_reset_ps>=0 && reserved_out[0]===1'b1 && cnn_busy_ps<0) begin
            cnn_busy_ps=now_ps();
            cnn_busy_clk_ps=clk_edge_ps;
            cnn_busy_cycle=cycle_count;
        end
    always @(posedge checkpoint_done)
        if(rst_n && workload_reset_ps>=0 && checkpoint_done===1'b1) begin
            cnn_done_rises=cnn_done_rises+1;
            if(cnn_done_ps<0) begin
                cnn_done_ps=now_ps();
                cnn_done_clk_ps=clk_edge_ps;
                cnn_done_cycle=cycle_count;
            end
        end
