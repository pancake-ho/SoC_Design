# STEP 1: work in a fresh synth directory; preserve existing outputs.
set_app_var sh_continue_on_error false
set_app_var sh_script_stop_severity E
if {[file exists work] || [file exists reports] || [file exists outputs]} {error "Existing synthesis work preserved; use a new copy."}
file mkdir work reports outputs
set_host_options -max_cores 2
source library_setup.tcl
proc clock_setting {name default min max} {
    if {![info exists ::env($name)]} {return $default}
    set value $::env($name)
    if {![regexp {^(0|[1-9][0-9]*)$} $value] || $value < $min || $value > $max} {
        error "$name must be an integer in ps from $min through $max"
    }
    return $value
}
set clock_period_ps [clock_setting EE470_CLK_PERIOD_PS 10000 20 1000000]
set clock_latency_ps [clock_setting EE470_CLK_LATENCY_PS 0 0 0]
if {$clock_period_ps % 2} {error "EE470_CLK_PERIOD_PS must be even for 1 ps half-cycles"}
set clock_period_ns [expr {$clock_period_ps / 1000.0}]

proc public_clock_period_ps {} {
    set core [get_clocks -quiet CORE_CLK]
    if {[sizeof_collection $core] != 1 || [get_object_name [get_attribute $core sources]] ne "clk"} {
        error "CORE_CLK must remain on the public clk port"
    }
    foreach_in_collection clock [remove_from_collection [all_clocks] $core] {
        set sources [get_attribute $clock sources]
        if {[sizeof_collection $sources] && "clk" in [get_object_name $sources]} {
            error "Declare additional clocks on internal sources; only CORE_CLK drives the public clk port"
        }
    }
    set period [get_attribute $core period]
    set ps [expr {round($period * 1000.0)}]
    set waveform [get_attribute $core waveform]
    if {[llength $waveform] == 1} {set waveform [lindex $waveform 0]}
    lassign $waveform rise fall
    if {$ps < 20 || $ps > 1000000 || $ps % 2 || abs($period * 1000.0 - $ps) > 0.001 ||
        [llength $waveform] != 2 || abs($rise) > 0.000001 || abs($fall - $period / 2.0) > 0.000001} {
        error "CORE_CLK requires a zero-phase 50% waveform and an even period in ps from 20 through 1000000"
    }
    return $ps
}

proc apply_scenario_constraints {period_ns} {
    set clk_port [get_ports clk]
    set inputs [remove_from_collection [all_inputs] [get_ports {clk rst_n}]]
    create_clock -name CORE_CLK -period $period_ns $clk_port
    if {[info exists ::env(EE470_EXTRA_SDC)] && $::env(EE470_EXTRA_SDC) ne ""} {
        source $::env(EE470_EXTRA_SDC)
        set core [get_clocks CORE_CLK]
        # Reapply the public environment after the team's internal constraints.
        remove_input_delay [all_inputs]
        remove_output_delay [all_outputs]
        remove_case_analysis [get_ports rst_n]
        remove_propagated_clock $core
        remove_propagated_clock $clk_port
        remove_clock_latency $core
        remove_clock_latency -source $core
        remove_clock_latency $clk_port
        remove_clock_latency -source $clk_port
        remove_clock_transition $core
    }
    set period_ps [public_clock_period_ps]
    set_clock_latency -source 0 [get_clocks CORE_CLK]
    set_clock_uncertainty -setup 0.20 [all_clocks]
    set_clock_uncertainty -hold 0.10 [all_clocks]
    set_input_transition 0.080 [remove_from_collection [all_inputs] $clk_port]
    set_input_delay -clock CORE_CLK -max 2.0 $inputs
    set_input_delay -clock CORE_CLK -min 0.5 $inputs
    set_false_path -from [get_ports rst_n]
    set_output_delay -clock CORE_CLK -max 2.0 [all_outputs]
    set_output_delay -clock CORE_CLK -min -0.4 [all_outputs]
    set_load 20.0 [all_outputs]
    set_scenario_options -setup true -hold true
    set_fix_hold [all_clocks]
    return $period_ps
}

proc check_project_ports {} {
    set expected {}
    foreach {direction name width} {
        in clk 1 in rst_n 1 in host_valid 1 in host_write 1
        in host_addr 32 in host_wdata 32 in start 1 in boot_addr 32 in reserved_in 8
        out host_ready 1 out host_rdata 32 out host_error 1 out busy 1 out done 1 out trap 1
        out commit_valid 1 out commit_pc 32 out commit_insn 32 out commit_rd 5
        out commit_wdata 32 out reserved_out 8
        in rp_aux_in0 8 in rp_aux_in1 8 in rp_aux_in2 8
        in rp_aux_in3 8 in rp_aux_in4 8 in rp_aux_in5 8 in rp_aux_in6 8
        out rp_aux_out0 8 out rp_aux_out1 8 out rp_aux_out2 8
        out rp_aux_out3 8 out rp_aux_out4 8 out rp_aux_out5 8 out rp_aux_out6 8
    } {
        for {set bit 0} {$bit < $width} {incr bit} {
            set port_name $name
            if {$width > 1} {set port_name [format {%s[%d]} $name $bit]}
            set port [get_ports -quiet $port_name]
            if {[sizeof_collection $port] != 1 || [get_attribute $port direction] ne $direction} {
                error "Fixed project_top port mismatch: $direction $port_name"
            }
            lappend expected $port_name
        }
    }
    if {[sizeof_collection [get_ports *]] != [llength $expected]} {
        error "Unexpected ports in project_top"
    }
}

# STEP 2: same RTL as VCS, with the actual SRAM macro selected.
set_app_var compile_seqmap_honor_sync_set_reset true
set_app_var compile_restructure_sync_set_reset false
define_design_lib WORK -path work/analyze
if {![info exists ::env(EE470_RTL_DEFINES)]} {error "Run bash run.sh to load the declared simulation profile"}
proc rtl_sources {directory} {
    set files [glob -nocomplain -types f -directory $directory *.v *.sv]
    foreach sub [glob -nocomplain -types d -directory $directory *] {
        set files [concat $files [rtl_sources $sub]]
    }
    return $files
}
analyze -format sverilog -define [concat USE_MACRO [split $::env(EE470_RTL_DEFINES)]] [lsort [rtl_sources ../rtl]]
elaborate project_top
current_design project_top
check_project_ports
if {![link]} {error "Link failed; black boxes are not accepted"}
if {![check_design]} {error "check_design failed"}
proc sram_inventory {destination} {
    set cells [get_cells -hierarchical -filter {ref_name =~ SRAM*}]
    if {[sizeof_collection $cells] < 2} {error "Expected separate real SRAM macros for IMEM and DMEM"}
    set refs {}
    set out [open $destination w]
    foreach_in_collection cell $cells {
        set ref [get_attribute $cell ref_name]
        if {[sizeof_collection [get_lib_cells -of_objects $cell]] != 1} {
            close $out
            error "SRAM library binding unresolved for $ref"
        }
        lappend refs $ref
        puts $out "[get_object_name $cell] $ref"
    }
    close $out
    return [lsort $refs]
}
set original_srams [sram_inventory reports/sram_instances_before.rpt]
set macros [get_cells -hierarchical -filter {ref_name =~ SRAM*}]
set_dont_touch $macros true
report_units > reports/units.rpt
report_reference -hierarchy > reports/reference_before.rpt
# STEP 3: six scenarios: SS/TT/FF times Cmax/Cmin; setup AND hold in every scenario.
# The subset takes exact .db entries from link_library; operating conditions use logical library names.
create_scenario SS0P95V125C_CMAX
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p95v125c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ss0p95v125c.db}
set_operating_conditions -library {saed32rvt_ss0p95v125c saed32sram_ss0p95v125c} ss0p95v125c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/SS0P95V125C_CMAX_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
create_scenario SS0P95V125C_CMIN
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p95v125c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ss0p95v125c.db}
set_operating_conditions -library {saed32rvt_ss0p95v125c saed32sram_ss0p95v125c} ss0p95v125c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/SS0P95V125C_CMIN_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
create_scenario TT1P05V25C_CMAX
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_tt1p05v25c.db}
set_operating_conditions -library {saed32rvt_tt1p05v25c saed32sram_tt1p05v25c} tt1p05v25c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/TT1P05V25C_CMAX_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
create_scenario TT1P05V25C_CMIN
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_tt1p05v25c.db}
set_operating_conditions -library {saed32rvt_tt1p05v25c saed32sram_tt1p05v25c} tt1p05v25c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/TT1P05V25C_CMIN_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
create_scenario FF1P16VN40C_CMAX
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ff1p16vn40c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ff1p16vn40c.db}
set_operating_conditions -library {saed32rvt_ff1p16vn40c saed32sram_ff1p16vn40c} ff1p16vn40c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmax.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/FF1P16VN40C_CMAX_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
create_scenario FF1P16VN40C_CMIN
set_link_library_subset -top {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ff1p16vn40c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ff1p16vn40c.db}
set_operating_conditions -library {saed32rvt_ff1p16vn40c saed32sram_ff1p16vn40c} ff1p16vn40c
set_tlu_plus_files -max_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -min_tluplus /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_1p9m_Cmin.tluplus -tech2itf_map /opt/eda/pdk/saed32nm/edk/SAED32_EDK/tech/star_rcxt/saed32nm_tf_itf_tluplus.map
check_tlu_plus_files > reports/FF1P16VN40C_CMIN_tlu.rpt
lappend scenario_periods [apply_scenario_constraints $clock_period_ns]
# Gate simulation and SAIF consume the effective CORE_CLK period, including a team SDC override.
if {[llength [lsort -unique $scenario_periods]] != 1} {
    error "Use one submitted CORE_CLK period throughout the six scenarios"
}
set clock_period_ps [lindex $scenario_periods 0]
set timing_run [open outputs/timing_run.txt w]
puts $timing_run "clock_period_ps=$clock_period_ps"
puts $timing_run "clock_latency_ps=$clock_latency_ps"
puts $timing_run "clock_model=ideal"
if {[info exists ::env(EE470_EXTRA_SDC_SHA256)]} {
    puts $timing_run "extra_sdc_sha256=$::env(EE470_EXTRA_SDC_SHA256)"
}
close $timing_run
puts "EE470_CLOCK period_ps=$clock_period_ps latency_ps=$clock_latency_ps model=ideal"

# STEP 4: optimize one shared implementation. Each scenario requests set_fix_hold.
# Teams may add hold optimization here while retaining the common SDC above.
# Inspect all min paths after mapping. A completed compile is not timing closure.
set_active_scenarios {SS0P95V125C_CMAX SS0P95V125C_CMIN TT1P05V25C_CMAX TT1P05V25C_CMIN FF1P16VN40C_CMAX FF1P16VN40C_CMIN}
current_scenario SS0P95V125C_CMAX
report_scenarios > reports/scenarios.rpt
report_scenario_options -scenarios {SS0P95V125C_CMAX SS0P95V125C_CMIN TT1P05V25C_CMAX TT1P05V25C_CMIN FF1P16VN40C_CMAX FF1P16VN40C_CMIN} > reports/scenario_options.rpt
set_fix_multiple_port_nets -all -buffer_constants
list_licenses
compile_ultra -no_autoungroup
list_licenses
change_names -rules verilog -hierarchy
check_project_ports
puts EE470_FIXED_PORTS_VERIFIED
set timing_run [open outputs/timing_run.txt a]
puts $timing_run "fixed_ports=verified"
close $timing_run
if {![check_design]} {error "Mapped design check failed"}
if {[sram_inventory reports/sram_instances_after.rpt] ne $original_srams} {
    error "SRAM inventory changed during synthesis"
}
# STEP 5: estimated physical RC and every PVT/RC setup/hold report.
extract_rc -estimate
current_scenario SS0P95V125C_CMAX
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/SS0P95V125C_CMAX_check_timing.rpt
report_case_analysis > reports/SS0P95V125C_CMAX_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/SS0P95V125C_CMAX_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/SS0P95V125C_CMAX_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/SS0P95V125C_CMAX_violators.rpt
write_sdc outputs/SS0P95V125C_CMAX.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/SS0P95V125C_CMAX.sdf
current_scenario SS0P95V125C_CMIN
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/SS0P95V125C_CMIN_check_timing.rpt
report_case_analysis > reports/SS0P95V125C_CMIN_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/SS0P95V125C_CMIN_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/SS0P95V125C_CMIN_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/SS0P95V125C_CMIN_violators.rpt
write_sdc outputs/SS0P95V125C_CMIN.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/SS0P95V125C_CMIN.sdf
current_scenario TT1P05V25C_CMAX
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/TT1P05V25C_CMAX_check_timing.rpt
report_case_analysis > reports/TT1P05V25C_CMAX_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/TT1P05V25C_CMAX_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/TT1P05V25C_CMAX_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/TT1P05V25C_CMAX_violators.rpt
write_sdc outputs/TT1P05V25C_CMAX.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/TT1P05V25C_CMAX.sdf
current_scenario TT1P05V25C_CMIN
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/TT1P05V25C_CMIN_check_timing.rpt
report_case_analysis > reports/TT1P05V25C_CMIN_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/TT1P05V25C_CMIN_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/TT1P05V25C_CMIN_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/TT1P05V25C_CMIN_violators.rpt
write_sdc outputs/TT1P05V25C_CMIN.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/TT1P05V25C_CMIN.sdf
current_scenario FF1P16VN40C_CMAX
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/FF1P16VN40C_CMAX_check_timing.rpt
report_case_analysis > reports/FF1P16VN40C_CMAX_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/FF1P16VN40C_CMAX_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/FF1P16VN40C_CMAX_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/FF1P16VN40C_CMAX_violators.rpt
write_sdc outputs/FF1P16VN40C_CMAX.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/FF1P16VN40C_CMAX.sdf
current_scenario FF1P16VN40C_CMIN
# Apply reset timing case only after compilation, preserving reset hardware.
set_case_analysis 1 [get_ports rst_n]
check_timing > reports/FF1P16VN40C_CMIN_check_timing.rpt
report_case_analysis > reports/FF1P16VN40C_CMIN_case_analysis.rpt
report_timing -delay_type max -significant_digits 4 -max_paths 20 > reports/FF1P16VN40C_CMIN_setup.rpt
report_timing -delay_type min -significant_digits 4 -max_paths 20 > reports/FF1P16VN40C_CMIN_hold.rpt
report_constraint -all_violators -significant_digits 4 > reports/FF1P16VN40C_CMIN_violators.rpt
write_sdc outputs/FF1P16VN40C_CMIN.sdc
write_sdf -version 2.1 -significant_digits 4 outputs/FF1P16VN40C_CMIN.sdf
# Verify the logical libraries actually used by the mapped design.
report_scenarios > reports/scenarios_mapped.rpt
# STEP 6: preserve one mapped netlist and native area reports.
report_area -hierarchy > reports/area.rpt
report_reference -hierarchy > reports/references.rpt
report_qor > reports/qor.rpt
write -format verilog -hierarchy -output outputs/project_mapped.v
write -format ddc -hierarchy -output outputs/project_mapped.ddc
# Gate activity and power are separate steps; this is pre-CTS/pre-route.
echo PROJECT1_BASELINE_TOPO_COMPLETE
quit
