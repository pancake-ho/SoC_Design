# 프로젝트 전력 측정 방법

v9.3은 추측한 toggle 비율 대신 실제 SDF 게이트 시뮬레이션에서 생성한 SAIF를 사용합니다.
SAIF는 Switching Activity Interchange Format입니다. 신호가 0과 1에 머문 시간과 전환 횟수를
DC NXT Topographical에 전달하여 라이브러리의 internal·switching·leakage power를 계산합니다.

## 같은 연산을 같은 조건으로 비교합니다

- 합성 top은 CPU·IMEM SRAM·DMEM SRAM·NPU를 모두 포함하는 `project_top`입니다.
- 공식 입력은 공개 F12의 seed 470입니다. 16×16 입력, 3×3 필터 4개, 7,056 MAC과 784개 출력을 계산합니다.
  허용된 패킹 설정은 유지하되 같은 논리 입력과 golden 결과를 사용합니다.
- 공식 클록은 기존 공통 10 ns, source latency 0입니다. 공통 SDC의 I/O·uncertainty·load·예외는 바꾸지 않습니다.
- SS/TT/FF × Cmax/Cmin 여섯 시나리오마다 해당 SDF로 실행한 활동을 해당 코너의 라이브러리에 연결합니다.
  TT 활동을 다른 모든 코너에 복제하지 않습니다.
- 창은 외부 `reserved_out[0]`의 첫 NPU_BUSY 상승부터 `reserved_out[1]`의 첫 DONE 상승까지입니다.
  기존 성능 체크포인트의 1 ps 좌표를 그대로 씁니다. 입력 적재·리셋·결과 덤프는 제외합니다.
  창 안에서는 CPU·모든 SRAM·NPU의 활동을 포함하며 CPU를 측정 대상에서 제거하지 않습니다.
- 동일한 논리 작업의 시작·종료로 창을 정하므로 설계별 창 길이는 다를 수 있습니다.
  짧게 끝난 설계를 긴 idle 시간으로 패딩해 평균 전력을 낮추지 않습니다.
  평균 전력 W와 함께 에너지 J = 평균 전력 W × 창 길이 s를 별도로 보고합니다.

## 실행 순서

이미 v9.2와 같은 RTL로 합성해 만든 netlist·DDC·SDF·6코너 STA가 있으면 재합성하지 않아도 됩니다.
RTL이나 공통 구현 조건을 바꿨다면 먼저 새 작업 사본에서 기존 합성을 다시 수행합니다.

```bash
# baseline_release 폴더에서 실행합니다.
python3 scripts/runner.py --suite public --tool vcs
cd synth
bash run.sh
cd ..

# 여섯 SDF 게이트 실행과 DUT 활동을 저장합니다.
python3 synth/gate_timing.py --saif

# 위 실행에서 출력한 GATE_RUN_DIR를 아래 실제 경로로 바꿉니다.
python3 synth/power_saif.py --gate-run synth/gate_timing_실제경로
```

`gate_timing.py`는 기능과 SDF 검사가 통과해도 STA hold가 음수이면 종료 코드 1을 반환할 수 있습니다.
이때 `gate_timing_summary.json`의 여섯 `gate_status`가 모두 PASS인 경우 전력 측정은 진단용으로
진행할 수 있습니다. 기능 실패·X·timeout·불완전한 SDF·모델 경고가 있으면 전력 단계가 중단됩니다.
종료 코드를 무조건 무시하거나 FAIL 문자열을 지우지 않습니다.

전력 단계는 기존 DDC를 읽고 각 코너에서 다음 명령을 수행합니다. 새로 합성하지 않습니다.

```tcl
current_scenario TT1P05V25C_CMAX
reset_switching_activity -all
read_saif -input TT1P05V25C_CMAX.saif \
    -instance_name tb_project/adapter/dut -auto_map_names
report_saif -hierarchy -missing
report_power -analysis_effort high -hierarchy
report_power -analysis_effort high
```

VCD의 시간 단위가 1 ps 또는 100 fs여도 도구가 읽은 timescale에 맞춰 창 좌표를 변환합니다.
SAIF의 DURATION × TIMESCALE이 DONE−BUSY와 같은지 검사합니다. 숫자를 그대로 ns로 가정하지 않습니다.
게이트 시뮬레이션의 SDF·timing check·notifier는 유지합니다.

## 어떤 파일을 읽고 제출하나요

`POWER_RUN_DIR`에 여섯 SAIF, 변환 명령·로그, DC 스크립트·로그, 코너별 activity annotation,
hierarchical power, power summary, `power_summary.json`이 생성됩니다.
기준형의 여섯 DUT VCD는 약 9 GB였습니다. 충분한 임시 공간을 준비하고, VCD 해시는
1 MB씩 나누어 계산해 큰 파일 전체를 메모리에 올리지 않습니다. SAIF와 로그를 검토한 후
대용량 VCD는 별도 보관하거나 본인의 생성 산출물만 정리할 수 있습니다.
`internal_W`, `switching_W`, `dynamic_W`, `leakage_W`, `total_W`, `energy_J`는 단위가 이름에 있습니다.
dynamic은 internal+switching이며 total에는 leakage도 포함합니다.
`mW`, `µW`, `pW`가 한 리포트 안에 섞일 수 있으므로 숫자만 더하지 않습니다.

SAIF의 계층은 TB 전체가 아니라 `tb_project/adapter/dut`와 맞아야 합니다.
`*_annotation.rpt`의 missing ports/nets/pins, default activity와 constant 신호를 확인합니다.
미주석 항목이 있으면 진단값은 남기되 자동 공식 자격은 false입니다.
항목을 0으로 채우거나 임의의 toggle 비율을 주어 통과시키지 않습니다.
SRAM은 주소·제어·데이터 활동 및 실제 매크로 라이브러리의 power 모델을 사용합니다.
접근 횟수 × 임의 상수를 전력으로 제출하거나 SRAM을 제외하지 않습니다.

여섯 코너 수치를 모두 제출하고 최악 total power를 별도 요약합니다. 기존 P·P·A별 상대평가와 배점은 유지합니다.
모든 기능·SDF·공통 STA setup/hold와 activity 검토를 통과해야 공식 전력 비교 대상입니다.
`diagnostic_worst_total_W`는 진단값이고 `qualified_worst_total_W`는 자격 미달이면 null입니다.
기준형의 hold는 각 조가 데이터 경로에서 보정하며, 공통 SDC를 완화해서 맞추면 안 됩니다.
power switch는 프로젝트에서 사용하지 않습니다.

이 결과는 ideal clock, pre-CTS·pre-route 추정입니다. 실제 CTS 버퍼·배선·IR-drop·열·패키지까지
검증한 signoff power가 아닙니다. 자체 clock-gating 구현은 root clock 전달, gated FF의 clock 도달,
gating check와 SAIF clock 활동을 별도로 증명해야 합니다.

## 기존 작업에 적용

v9.2 작업용 패치는 `rtl/`, `config/`, 공통 SDC, 기존 netlist·DDC·SDF를 덮어쓰지 않습니다.
`tb/common/tb_project.v`의 활동 저장 부분과 전력 실행 파일만 업데이트합니다.
공식 TB를 수정한 팀은 먼저 본인 변경을 따로 보관하고 깨끗한 교강사 harness로 최종 검증합니다.
새 게이트 실행에서 `--saif`를 지정해야 하며, 예전의 전력 활동 없는 로그만으로 SAIF를 만들 수는 없습니다.
