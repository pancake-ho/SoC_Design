# v9.2 게이트 타이밍 모델 실제 재검증

2026년 11월 19일 dice에서 VCS V-2023.12-SP2-1로 실행했습니다. v9.1의 동일 mapped netlist,
동일 여섯 원본 SDF, 동일 입력 벡터를 사용했습니다. RTL·NDM·SDC·STA는 바꾸지 않았습니다.

## 여섯 시나리오

| Scenario | F12 checks | errors | WSUM | NTCDNC | setup WNS ns | hold WNS ns |
|---|---:|---:|---:|---:|---:|---:|
| FF1P16VN40C_CMAX | 24287 | 0 | 0 | 0 | 5.0109 | -0.4315 |
| FF1P16VN40C_CMIN | 24287 | 0 | 0 | 0 | 5.0422 | -0.4319 |
| SS0P95V125C_CMAX | 24287 | 0 | 0 | 0 | 0.5755 | -0.3122 |
| SS0P95V125C_CMIN | 24287 | 0 | 0 | 0 | 0.6417 | -0.3133 |
| TT1P05V25C_CMAX | 24287 | 0 | 0 | 0 | 3.7344 | -0.3852 |
| TT1P05V25C_CMIN | 24287 | 0 | 0 | 0 | 3.772 | -0.3859 |

모두 functional_status=PASS, gate_status=PASS, sdf_complete=true입니다.
SDF annotation 경고와 실행 중 timing violation은 0개입니다. 모든 시나리오의 F12는 protocol_errors=0,
105,840 cycles이며 원본 netlist·벡터 SHA256도 v9.1 실행과 같습니다.

## 원인과 수정의 범위

- SRAM은 일부 setup+hold 합이 최저 −0.3 ps였습니다. 시뮬레이션 사본에서 각 한계값을
  1 ps 격자로 큰 값 방향으로 올려 검사창을 보수적으로 표현합니다. 변경은 각 값당 1 ps 미만이며
  원본 SDF와 STA는 유지합니다. 원본/적용값은 model_timing_audit.json에 기록합니다.
- DFFSSRX1/2의 SDF 미사용 0폭 선언 9개씩이 음수 검사 지연 계산을 방해했습니다.
  SDF가 해당 선언을 사용하지 않는지 확인한 뒤 사본에서만 제외합니다.
  실제 타이밍 검사·기능 논리·notifier·출력 경로는 유지합니다.
- +neg_tchk +overlap+new_solver를 사용하며 경고 출력·타이밍 검사·notifier를 끄지 않았습니다.

## 타이밍 검사가 살아 있는지 확인한 대조 시험

실제 SAED32 모델과 TT/CMAX SDF에서 여섯 조건을 실행했습니다.

| 조건 | 기대 | 실제 |
|---|---|---|
| 정상 DFF·SRAM 입력 | 위반 없음 | 0개 |
| DFF D 상승, clock 70 ps 전 변경 | 위반 검출 | DFF 1개 |
| DFF D 하강, clock 32 ps 전 변경 | 위반 검출 | DFF 1개 |
| D 상승, 음수 hold 허용창에 해당하는 clock 10 ps 전 변경 | 위반 없음 | 0개 |
| D 하강, 해당 위반창 밖인 clock 50 ps 전 변경 | 위반 없음 | 0개 |
| SRAM CSB 하강, clock 50 ps 전 변경 | 위반 검출 | SRAM 1개 |

## 학생의 hold 보정과 구분

위 표의 setup/hold STA 수치는 v9.1과 모두 동일합니다. 기준형의 hold 위반은 여전히 남아
all_scenarios_qualified=false입니다. 모델 경고가 없는 게이트 기능 PASS가 STA hold 통과를
대신하지 않습니다. 팀은 공통 SDC를 유지하며 set_fix_hold와 데이터 경로 최적화로 보정합니다.
v9.1에서 적용할 때 재합성은 필요 없고 게이트 실행만 다시 합니다. 이전 리셋 수정이 없는
v9 사용자는 v9.1 리셋 수정과 재합성이 먼저 필요합니다.
