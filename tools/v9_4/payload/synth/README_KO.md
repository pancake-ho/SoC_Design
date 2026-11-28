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
