#!/usr/bin/env bash
# Local alternate backend. These results do not represent a VCS run.
set -euo pipefail
mkdir build logs
iverilog -g2012 '-DUSE_MACRO' '-DSOC_MMIO_BASE=1024' '-DSOC_CONST_BASE=1536' -I../../tb/common -I../../tb/cases -I../../tb/student -s tb_project ../../rtl/npu.v ../../rtl/winograd/winograd_tile_engine.v ../../rtl/project_top.v ../../rtl/riscvsingle.sv ../../rtl/soc_system.v ../../rtl/sram_wrapper.v ../../tb/adapter/dut_adapter.v ../../tb/common/tb_project.v /opt/eda/pdk/saed32nm/edk/SAED32_EDK/lib/sram/verilog/saed32sram.v -o build/simv
timeout 120s vvp build/simv '+CASE=F03' '+VECTORS=vectors.hex' '+WAVES=1' | tee logs/simulation.log
cat raw_result.json
