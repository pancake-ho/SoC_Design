# Team power measurement only. Uses the same netlist, SDC, estimated RC and
# gate workload. No library files, timing exceptions or license settings changed.
set_app_var sh_continue_on_error false
set_app_var sh_script_stop_severity E
set_app_var power_enable_analysis true
set_app_var power_analysis_mode averaged
set source $env(EE470_SOURCE)
set scenario $env(EE470_SCENARIO)
set activity $env(EE470_ACTIVITY)
set pvt [lindex [split $scenario _] 0]
switch $pvt {
    SS0P95V125C {set corner ss0p95v125c}
    TT1P05V25C {set corner tt1p05v25c}
    FF1P16VN40C {set corner ff1p16vn40c}
    default {error "Unknown common scenario"}
}
set pdk /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib
set std [file join $pdk stdcell_rvt db_nldm saed32rvt_${corner}.db]
set ram [file join $pdk sram db_nldm saed32sram_${corner}.db]
foreach path [list $std $ram] {if {![file readable $path]} {error "Missing library $path"}}
set_app_var link_path [list * $std $ram]
read_verilog [file join $source synth outputs project_mapped.v]
current_design project_top
if {![link_design project_top]} {error "Power netlist link failed"}
read_sdc [file join $source synth outputs ${scenario}.sdc]
set_operating_conditions -library [list saed32rvt_${corner} saed32sram_${corner}] $corner
read_parasitics [file join $source synth outputs ${scenario}.spef]
read_sdf [file join $source synth outputs ${scenario}.sdf]
update_timing
check_timing > check_timing.rpt
report_units > units.rpt
report_annotated_parasitics > parasitics.rpt
report_annotated_delay -cell -net > delay_annotation.rpt
read_vcd -strip_path tb_project/adapter/dut $activity
update_power
report_switching_activity -coverage -hierarchy > activity_coverage.rpt
report_switching_activity -list_not_annotated > activity_missing.rpt
report_power -hierarchy -levels 3 -unit W -nosplit > power_hierarchy.rpt
report_power -unit W -nosplit > power_total.rpt
set macros [get_cells -hierarchical -filter {ref_name =~ SRAM*}]
if {[sizeof_collection $macros] < 2} {error "Real IMEM/DMEM macros missing from power design"}
report_power -cell_power -verbose -include_lib_cells -unit W -nosplit $macros > power_sram.rpt
puts EE470_TEAM_POWER_REPORTS_COMPLETE
exit
