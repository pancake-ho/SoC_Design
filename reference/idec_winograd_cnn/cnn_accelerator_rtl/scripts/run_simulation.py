#!/usr/bin/env python3
"""Build and run the CNN accelerator testbenches from any working directory."""

import argparse
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
SUBMITTED = ROOT / "original"
SUBMITTED_ENGINE = SUBMITTED / "rtl/submitted_shift_add_engine.sv"
MODULE_DECLARATION = re.compile(r"^module[ \t]+(\w+)", re.MULTILINE)


def read_rtl_filelist():
    sources = []
    includes = []
    for line in (ROOT / "rtl/sources.f").read_text(encoding="ascii").splitlines():
        line = line.strip()
        if line.startswith("+incdir+"):
            includes.append(ROOT / line.removeprefix("+incdir+"))
        elif line:
            sources.append(ROOT / line)
    return sources, includes


def submitted_top(testbench):
    names = MODULE_DECLARATION.findall(testbench.read_text(encoding="utf-8"))
    if len(names) != 1:
        raise ValueError(f"Expected one module in {testbench.name}, got {len(names)}")
    return names[0]


def select_test(test, build):
    if test == "gls":
        testbench = SUBMITTED / "tb/submitted_gate_tb.sv"
        sources = sorted((SUBMITTED / "stdcell").glob("*.v"))
        sources += [SUBMITTED / "synthesis/submitted_gate_netlist.v", testbench]
        return submitted_top(testbench), sources, []
    if test == "original":
        testbench = SUBMITTED / "tb/submitted_inference_tb.sv"
        sources = [SUBMITTED_ENGINE, SUBMITTED / "rtl/submitted_cnn_core.sv", testbench]
        return submitted_top(testbench), sources, []

    sources, includes = read_rtl_filelist()
    if test == "engine":
        top = "tb_shared_engine_equivalence"
        original_text = SUBMITTED_ENGINE.read_text(encoding="utf-8")
        renamed, count = MODULE_DECLARATION.subn("module reference_shift_add_engine", original_text)
        if count != 1:
            raise ValueError(f"Expected one original module declaration, got {count}")
        alias = build / "reference_shift_add_engine.sv"
        alias.write_text(renamed, encoding="utf-8")
        sources.append(alias)
    else:
        top = "tb_cnn_inference"
        includes.append(ROOT / "tb")
    return top, [*sources, ROOT / f"tb/{top}.sv"], includes


def run(command, cwd, log, expected=None):
    print(f"> {shlex.join(map(str, command))}", flush=True)
    with log.open("w", encoding="utf-8") as output:
        result = subprocess.run(command, cwd=cwd, stdout=output, stderr=subprocess.STDOUT)
    message = log.read_text(encoding="utf-8", errors="replace")
    if result.returncode or (expected and expected not in message):
        print(message[-12000:], file=sys.stderr)
        raise RuntimeError(f"Failed, see {log}")
    if expected:
        print(message, end="")
    print(f"Log: {log.relative_to(ROOT)}")


def executable(name):
    path = shutil.which(name)
    if not path:
        raise RuntimeError(f"{name} was not found on PATH")
    return path


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("test", choices=("rtl", "engine", "original", "gls"))
    parser.add_argument("--sim", choices=("verilator", "xsim"), default="verilator")
    parser.add_argument("--verilator", default="verilator", help="Verilator executable name or path")
    parser.add_argument("--verilator-arg", action="append", default=[], help="Extra build option, repeatable")
    parser.add_argument("--images", type=int, choices=range(1, 1001), default=1000, metavar="1..1000")
    parser.add_argument("--jobs", type=int, default=4)
    args = parser.parse_args()
    if args.test == "gls" and args.sim != "xsim":
        parser.error("gls uses XSim with the submitted ASAP7 cell models")

    build = ROOT / f"build/{args.sim}/{args.test}"
    build.mkdir(parents=True, exist_ok=True)
    top, sources, includes = select_test(args.test, build)
    expected = {
        "rtl": f"PYTHON ORACLE PASS: predictions={args.images} FC scores={10*args.images}",
        "original": f"PYTHON ORACLE PASS: predictions={args.images} FC scores={10*args.images}",
        "engine": "ENGINE EQUIVALENCE PASS:",
        "gls": f"NETLIST ORACLE PASS: predictions={args.images}/{args.images}",
    }[args.test]

    if args.sim == "verilator":
        # Simulate from the bundle root so these plusargs also work in paths with spaces.
        plusargs = [] if args.test == "engine" else [f"NUM_IMAGES={args.images}"]
        command = [executable(args.verilator), "--binary", "--timing", "-Wno-fatal",
                   "-j", str(args.jobs), "--Mdir", str(build.relative_to(ROOT)), "--top-module", top]
        command += [*args.verilator_arg, *(f"-I{p.relative_to(ROOT)}" for p in includes)]
        command += [str(p.relative_to(ROOT)) for p in sources]
        run(command, ROOT, build / "compile.log")
        binary = build / f"V{top}"
        run([str(binary), *("+" + arg for arg in plusargs)], ROOT, build / "simulate.log", expected)
    else:
        project = build / "sources.prj"
        # Match the submitted XSim project convention. RTL/TB is SV; cell models are Verilog.
        project.write_text("".join(
            f'{"sv" if source.suffix == ".sv" else "verilog"} xil_defaultlib "{source.as_posix()}"\n'
            for source in sources
        ), encoding="utf-8")
        include_opts = [item for path in includes for item in ("-i", str(path))]
        run([executable("xvlog"), "-prj", str(project), *include_opts], build, build / "compile.log")
        run([executable("xelab"), "--relax", "--snapshot", top, f"xil_defaultlib.{top}"],
            build, build / "elaborate.log")
        # Paths relative to the simulation working directory avoid spaced plusarg values.
        plusargs = [] if args.test == "engine" else [
            "DATA_DIR=../../../data", "ORACLE_DIR=../../../reference", f"NUM_IMAGES={args.images}"
        ]
        sim_opts = [item for arg in plusargs for item in ("-testplusarg", arg)]
        run([executable("xsim"), top, "-runall", *sim_opts], build, build / "simulate.log", expected)


if __name__ == "__main__":
    try:
        main()
    except (OSError, RuntimeError, ValueError) as error:
        sys.exit(str(error))
