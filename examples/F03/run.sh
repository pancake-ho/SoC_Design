#!/usr/bin/env bash
# Enter examples/F03 before running. Existing build/log/vector folders are preserved.
set -euo pipefail
mkdir build logs
vcs_queue -full64 -sverilog -timescale=1ns/1ps '+define+USE_MACRO' '+define+SOC_MMIO_BASE=1024' '+define+SOC_CONST_BASE=1536' +incdir+../../tb/common +incdir+../../tb/cases +incdir+../../tb/student -top tb_project ../../rtl/npu.v ../../rtl/project_top.v ../../rtl/riscvsingle.sv ../../rtl/soc_system.v ../../rtl/sram_wrapper.v ../../tb/adapter/dut_adapter.v ../../tb/common/tb_project.v /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/verilog/saed32sram.v -o build/simv -l logs/compile.log
timeout 120s build/simv '+CASE=F03' '+VECTORS=vectors.hex' '+WAVES=1' | tee logs/simulation.log
cat raw_result.json
