# 팀 클록과 공통 합성·게이트·SAIF 검증

| 항목 | 제출 조건 |
|---|---|
| 외부 `CORE_CLK` | 조별 주기 선택, 기본 예제 10 ns. DUT의 `clk`에 연결하며 ideal, 50% 듀티, 위상 0, source latency 0을 유지합니다. |
| 내부 클록과 제약 | 내부 NPU 클록, generated clock, 실제 CDC·클록 관계와 내부 경로 제약을 팀 SDC로 추가합니다. 사용한 SDC 전체를 제출합니다. |
| 외부 reset | `rst_n` active-low, 공통 TB의 리셋 순서와 적재 데이터 보존·리셋 중 쓰기 차단을 유지합니다. |
| I/O delay | 데이터 입력 max/min 2.0/0.5 ns, 출력 max/min 2.0/−0.4 ns. 기준은 `CORE_CLK` 상승 에지입니다. `clk`, `rst_n`에는 데이터 입력 지연을 적용하지 않습니다. |
| Input transition / output load | 비클록 입력 0.080 ns, 출력 20 fF. `report_units`를 제출합니다. |
| Clock uncertainty | setup 0.20 ns, hold 0.10 ns. |

새 작업 사본의 `synth/`에서 실행합니다. RTL 실습에서 같은 클록을 쓰려면 `scripts/run.sh --clock-period-ps 12000`을 지정합니다.

```bash
cd synth
EE470_CLK_PERIOD_PS=12000 bash run.sh --sdc ../team.sdc
```

`--sdc`는 선택 사항입니다. 팀 SDC에서 같은 `CORE_CLK`의 주기를 직접 선언할 수도 있습니다. 그 경우 실제로 적용된 SDC의 주기를 `outputs/timing_run.txt`에 기록하고 게이트 검증이 읽습니다. 클록의 주기는 여섯 시나리오에서 동일해야 합니다. 1 ps 파형으로 50% 듀티를 생성하므로 주기는 20–1,000,000 ps 범위의 짝수 정수로 입력합니다.

팀 SDC가 여러 파일이면 진입점에서 `source [file join [file dirname [info script]] internal_clocks.sdc]`처럼 읽습니다. 흐름이 시나리오마다 팀 SDC를 읽고 공통 포트 지연·부하·입력 transition과 clock uncertainty를 적용합니다. 생성된 여섯 `outputs/*.sdc`, `report_units`와 `check_timing`으로 최종 적용을 확인합니다. 내부 클록 분주를 바꾸려면 실제 RTL 클록 회로와 SDC 정의를 맞춥니다.

새 고정 top으로 합성하고 `sram_instances_before.rpt`와 `sram_instances_after.rpt`에서 IMEM/DMEM 매크로를 확인합니다.
same-netlist 여섯 시나리오에서 setup·hold를 확인합니다. 데이터 경로에 delay cell 또는 hold buffer를 배치한 뒤 모두 재검증합니다.
공개 포트 적재를 마친 뒤 측정용 `rst_n` 상승부터 유효 DONE까지 실행시간을 잽니다. 동일 구간의 DUT SAIF로 평균 전력과 에너지를 구합니다. 연습은 랜덤 입력, 평가는 교수자 지정의 F12 snapshot과 SHA256을 사용합니다.
명령과 결과 키는 [v10 테스트벤치 안내](../docs/TESTBENCH_V10_KO.md)를 보세요.

## 이전 버전 참고 기록

# v9.2 합성 및 게이트 실행

새 작업 사본의 synth/에서 bash run.sh를 실행합니다. 실제 표준셀·SRAM NDM은 /home/soc/common/saed32_ndm_20261112/full_pvt/에서 절대경로로 참조합니다.
DC NXT Topographical와 ideal clock을 사용하며 Fusion P&R는 하지 않습니다.
EE470_CLK_PERIOD_PS와 EE470_CLK_LATENCY_PS로 클록을 설정합니다. 나머지 공통 SDC는 바꾸지 않습니다.
set_fix_hold와 팀별 데이터 경로 최적화로 hold를 보정합니다.

프로젝트 루트에서:
```bash
python3 synth/gate_timing.py --scenario SS0P95V125C_CMAX
python3 synth/gate_timing.py --scenario SS0P95V125C_CMAX --waves
python3 synth/gate_timing.py
```
기본은 큰 gate VCD를 저장하지 않습니다. --waves를 지정한 경우에만 activity.vcd를 생성합니다.
전체 여섯 시나리오의 STA·게이트·SDF·timing-model 경고를 모두 확인합니다.
게이트 F12의 X/timeout은 동기식 reset 보존으로 수정했습니다. v9.2에서 SS/TT의 WSUM·NTCDNC도 해결했습니다. 여섯 시나리오 gate_status=PASS이며 STA hold 위반은 별도입니다. v9.1의 원본 netlist·SDF는 재사용할 수 있습니다. 현재 최종 timing 자격은 없으며 ../docs/VALIDATION.md를 확인합니다.
v8.1의 SDF 모델 연결 수정은 포함돼 있습니다. 예전 SDF 패치를 v9에 다시 덮어쓰지 않습니다.


## v9.3 SAIF 전력 분석

`python3 synth/gate_timing.py --saif`를 baseline_release에서 실행합니다.
여섯 코너의 gate 결과가 모두 PASS여야 `power_saif.py --gate-run <GATE_RUN_DIR>`를 실행할 수 있습니다.
STA hold 실패 상태의 값은 진단용이며 공식 자격은 false입니다.
기본 gate 실행은 기존처럼 큰 VCD를 만들지 않습니다. `--saif`는 power 분석에 필요한 DUT의 mapped 계층 VCD를 저장합니다. 충분한 디스크 공간을 준비하세요.
후처리까지 검토한 뒤 큰 VCD는 별도 보관할 수 있습니다. SAIF·JSON·로그·hash는 제출 근거로 유지합니다.
정확한 창·단위·활동 연결·라이브러리 범위와 해석은 `docs/POWER_SAIF_KO.md`를 따릅니다.


## v9.4 활동 연결 수정

게이트 SAIF는 RTL 이름 자동 매핑 없이 읽고 실제 연결 net의 비트별 값을 검증합니다.
NC output만 coverage에서 제외하며 모든 셀 전력은 유지합니다.
동일 v9.3 netlist·DDC·SDF와 --saif VCD를 그대로 재사용할 수 있습니다.
SS/TT SRAM의 음수 internal·누설 0은 모델 한계로 기록합니다.
실행 명령과 자세한 판정은 ../docs/POWER_SAIF_KO.md를 따릅니다.
