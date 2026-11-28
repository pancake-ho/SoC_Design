# v10.2 실행시간·에너지 측정과 활동 검증

v10 top 포트로 이관한 뒤 새 합성 DDC와 SDF를 생성하세요. 측정용 리셋과 VCD 구간도 v10에서 바뀌었습니다.

```bash
(cd synth && bash run.sh)
python3 synth/gate_timing.py --saif
python3 synth/power_saif.py --gate-run GATE_RUN_DIR
```

`GATE_RUN_DIR`에는 앞 단계에서 출력된 실제 경로를 넣으세요. 동일한 설계의 netlist·DDC·SDF·VCD를 사용합니다.

## 같은 연산과 측정 범위

- Top은 CPU·IMEM SRAM·DMEM SRAM·NPU를 포함하는 project_top입니다. 모든 매크로를 포함합니다.
- F12의 16×16 입력, 3×3 필터 4개로 7,056 MAC과 784개 출력을 계산합니다. 연습은 랜덤 입력을 생성합니다. 평가 시에는 교수자가 지정한 같은 F12 snapshot과 SHA256을 모든 조와 시나리오에 적용합니다.
- 제출 클록 주기는 조별로 정합니다. 게이트와 SAIF가 합성에 적용된 실제 주기를 사용합니다. source latency 0, 리셋, 포트 지연·transition·load와 공통 uncertainty는 유지합니다.
- SS/TT/FF × Cmax/Cmin 각각의 SDF 활동을 해당 코너의 라이브러리에 연결합니다.
- 사전 적재 후 측정용 `rst_n` 상승부터 유효한 `reserved_out[1]` DONE 상승까지 측정합니다.
  기존 1 ps 체크포인트 좌표를 사용하며, VCD/SAIF의 실제 timescale을 읽어 정확히 변환합니다.
- 초기 적재·리셋 인가·후속 읽기·TB 활동은 창 바깥이며, 창 안의 CPU·모든 SRAM·NPU를 포함합니다.
  빨리 끝난 설계를 idle로 패딩하지 않습니다. W와 J=평균 전력×실행 시간을 함께 기록합니다.

## 수정한 활동 연결

게이트 시뮬레이션과 같은 mapped DDC를 읽습니다. 이 SAIF는 이미 게이트 이름이므로
RTL 이름 자동 매핑 옵션 -auto_map_names를 사용하지 않습니다.

```tcl
current_scenario TT1P05V25C_CMAX
reset_switching_activity
read_saif -input TT1P05V25C_CMAX.saif -instance_name tb_project/adapter/dut
propagate_switching_activity
report_saif -hierarchy -missing
report_power -analysis_effort high -hierarchy
report_power -analysis_effort high
```

도구가 '주석됨'이라고 표시한 것만으로 충분하지 않습니다. v9.4는 실제 연결 net을 따라
각 비트 SAIF의 상태 시간·전환 횟수와 DC의 net·연결 핀·포트 activity를 대조합니다.
핀 자체의 SAIF 기록이 있으면 그 기록을 우선합니다. SDF 배선 지연 때문에 핀과 앞단 net의
전환이 측정 창 경계에서 한 번 달라질 수 있기 때문입니다. 핀 기록이 없으면 연결 net과 비교합니다.
배열의 한 원소나 다른 비트 값이 붙으면 bitwise_mismatch_count가 증가하고 자동 자격을 주지 않습니다.
상수 신호는 측정값과 일치하는지 확인합니다. SAIF의 TX/TZ도 별도 기록하며 임의로 0으로 채우지 않습니다.
SAIF에 직접 없는 net은 STA가 실제 상수 0/1·전환 0으로 판정한 경우를 따로 기록합니다.
그 밖의 미측정 비상수 net은 통과시키지 않습니다.
X 시간을 제외한 known-state 확률과 도구의 기본 inertial-glitch 환산을 같은 단위로 비교합니다.

미주석 핀은 실제 연결 정보로 분류합니다. **방향이 output이고 연결 net이 0개인 핀만**
활동 coverage 분모에서 제외합니다. 해당 셀 자체의 internal·leakage power는 계속 포함합니다.
연결된 핀·net·포트의 미주석 항목이나 값 불일치는 그대로 실패입니다. 미연결 input까지 면제하지 않습니다.
따라서 raw missing 개수가 커져도 실제 비트 연결이 정확하고 모두 NC output이면 통과할 수 있습니다.
raw missing이 적거나 0이어도 값이 다른 비트에 붙었다면 실패입니다.
PWR-452처럼 SAIF의 일부 이름이 DDC에 없다는 원본 경고도 보존합니다. 경고 개수만으로
통과시키지 않고 실제 DDC의 연결 net·핀·포트 coverage와 비트 감사 결과를 함께 확인합니다.

## 결과와 자격을 읽는 방법

POWER_RUN_DIR의 power_summary.json, reports/*_activity_audit.json,
*_annotation.rpt, *_net_activity.rpt, *_pin_activity.rpt, *_port_activity.rpt,
pin_connectivity.tsv 및 원본 power·hierarchy 보고서를 함께 봅니다.

- bitwise_mismatch_count: 측정 SAIF와 DC activity가 다른 net·핀·포트 레코드 수
- disconnected_output_pin_count: 구조로 확인한 미연결 output 핀 수
- unresolved_non_annotated_pin_count: 면제할 수 없는 미주석 핀 수
- activity_coverage_complete: 미해결 누락과 비트별 값 불일치가 없는지 여부
- memory_model_observation: SRAM을 포함한 memory 그룹의 원본 수치와 모델 한계 표시
- measured_unknown_records: TX/TZ가 포함된 감사 레코드 수로, 고유 신호 비율이나 정확도 %가 아님
- internal_W·switching_W·dynamic_W·leakage_W·total_W·energy_J: 단위가 명시된 결과

여섯 시나리오의 기능·완전한 SDF·모델 검사·STA setup/hold·활동 검증, 교수자 고정 벡터의 일치와 공통 클록 조건을
모두 만족해야 common_power_eligible=true입니다. 스코어에는 qualified_worst_energy_J를 사용합니다.
자격이 부족하면 이 값은 null이고 diagnostic_worst_energy_J에는 진단값을 보존합니다. hold는 각 조가 set_fix_hold 및 허용된
데이터 경로 보정으로 해결합니다. 공통 SDC를 완화하지 않습니다. gate_status가 모두 PASS여도
STA hold 때문에 게이트 실행의 종료 코드가 1일 수 있으며 이를 전력 연결 버그와 혼동하지 않습니다.

## SRAM power 모델의 한계

배포 SAED32 교육용 SRAM 라이브러리에서는 SS/TT memory internal이 음수이고 leakage가 0인
결과가 나타날 수 있습니다. 0 leakage를 실제 SRAM의 누설이 없다는 뜻으로 해석하면 안 됩니다.
이 개정은 PDK의 특성화 값을 새로 만들거나 정확성을 보증하는 수정이 아닙니다.
library_power_model_limitations와 memory_model_observation에 그 한계를 기록하고 원본값을 보존합니다.
음수를 0으로 clamp하거나 누설을 임의 숫자로 바꾸거나 SRAM을 빼지 않습니다.
기존 평가 조건에 따라 같은 라이브러리·측정 창의 전체 modeled total과 여섯 코너 값을 제출합니다.
결과는 ideal-clock pre-CTS·pre-route 비교 추정이며 SRAM signoff 전력이 아닙니다.
power switch는 프로젝트에서 사용하지 않습니다.

대용량 DUT VCD를 만들므로 충분한 임시 공간을 확보합니다. 감사 후 VCD를 정리하더라도
SAIF·원본 보고서·JSON·hash는 제출 근거로 유지합니다.
