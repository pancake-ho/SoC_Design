// Additional vectors are generated with the same independent golden.
task run_student_cases;
    integer frame;
    begin
        for(frame=0;frame<vectors[0];frame=frame+1) run_frame(frame);
    end
endtask
