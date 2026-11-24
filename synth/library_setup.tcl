# Site-specific logical timing mapping. Students normally do not edit these paths.
# NDM contains the shared physical views and SS/TT/FF timing panes.
set_app_var sh_continue_on_error false
set_app_var sh_script_stop_severity E
if {![shell_is_dcnxt_shell]} {error "Use dcnxt_topo_queue: NDM requires DC NXT"}
if {![shell_is_in_topographical_mode]} {error "Topographical mode required"}
set rvt_ndm /home/soc/common/saed32_ndm_20261112/full_pvt/saed32_rvt_ss_tt_ff.ndm
set sram_ndm /home/soc/common/saed32_ndm_20261112/full_pvt/saed32_sram_ss_tt_ff.ndm
foreach ndm [list $rvt_ndm $sram_ndm] {
    if {![file readable [file join $ndm reflib.ndm]]} {
        error "Cannot read the shared NDM: $ndm. Run on dice with your EE470 account."
    }
}
set_app_var target_library {/opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p95v125c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ff1p16vn40c.db}
set_app_var link_library {* /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ss0p95v125c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_tt1p05v25c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/stdcell_rvt/db_nldm/saed32rvt_ff1p16vn40c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ss0p95v125c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_tt1p05v25c.db /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/db_nldm/saed32sram_ff1p16vn40c.db}
# Reuse technology stored in the reference NDM; no separate student technology-file copy.
create_lib -use_technology_lib $rvt_ndm -ref_libs [list $rvt_ndm $sram_ndm] work/design.nlib
if {![shell_is_in_ndm_mode]} {error "NDM mode was not entered"}
puts "EE470_SHARED_NDM rvt=$rvt_ndm sram=$sram_ndm"
echo "PROJECT1_NDM_MODE_CONFIRMED"
