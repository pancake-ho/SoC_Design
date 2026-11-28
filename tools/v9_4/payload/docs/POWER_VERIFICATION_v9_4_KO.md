# v9.4 기준형 실제 검증 결과

2026년 11월 24일 dice의 교강사 전용 QA 사본에서 실행했습니다.
VCS V-2023.12-SP2-1, DC NXT Topographical V-2023.12-SP5를 사용했습니다.
v9.3과 동일한 RTL·mapped netlist·DDC·여섯 SDF·공통 SDC를 사용하며,
검증 사본의 NDM 접근 경로만 교강사가 읽을 수 있는 같은 라이브러리 원본으로 연결했습니다.
학생 작업·학생 계정·PDK·공통 SDC는 수정하지 않았습니다.

## 재현과 수정

같은 TT Cmax SAIF/DDC의 수정 전후 대조에서 기존 RTL 이름 자동 매핑은
net·핀 활동 279건을 측정값과 다르게 연결했습니다. 게이트 이름 직접 연결에서는
그 불일치가 0건이었습니다. report_saif의 '주석됨'만으로는 오매핑을 판별할 수 없습니다.
기존 활동 충돌 PWR-19도 직접 이름 연결 후 나타나지 않았습니다.

최종 감사는 핀 자체의 측정 기록이 있으면 이를, 없으면 실제 연결 net을 사용합니다.
SDF 배선 지연 때문에 측정 창 경계에서 핀과 앞단 net의 전환 수가 한 번 다를 수 있음을
실제 SRAM CSB 핀에서 확인했습니다. 허용 오차를 임의로 늘려 해결하지 않았습니다.

기준형의 raw missing은 ports 0·nets 0·pins 3,538이며, 핀은 모두 실제 NC output입니다.
이 핀만 활동 coverage에서 제외하고 해당 셀의 internal·leakage power는 유지합니다.
SAIF에 직접 없는 net 254개는 STA 상수 0/1·전환 0으로 별도 확인합니다.
연결 신호 누락과 비상수 미측정 net을 통과시키지 않습니다.
SAIF의 일부 소스 이름을 DDC에서 찾지 못하는 PWR-452 등 원본 경고도 보존합니다.

## 공개 기능과 여섯 코너

공개 F01–F12를 실제 SRAM 모델과 VCS로 실행해 모두 PASS를 확인했습니다.
F07의 필수 양/음 × 포화/wrap 오버플로 네 건도 유지됐습니다.
여섯 F12 게이트 실행은 기능·SDF annotation·모델 검사를 모두 통과했습니다.
SDF 경고, NTCDNC/WSUM 모델 경고와 실행 중 timing violation은 0입니다.

| Scenario | Gate | F12 checks | Setup WNS ns | Hold WNS ns | Bit mismatches | Total mW |
|---|---|---:|---:|---:|---:|---:|
| FF1P16VN40C_CMAX | PASS | 24287 | 5.0109 | -0.4315 | 0 | 166.7400 |
| FF1P16VN40C_CMIN | PASS | 24287 | 5.0422 | -0.4319 | 0 | 166.7800 |
| SS0P95V125C_CMAX | PASS | 24287 | 0.5755 | -0.3122 | 0 | 6.2297 |
| SS0P95V125C_CMIN | PASS | 24287 | 0.6417 | -0.3133 | 0 | 6.2063 |
| TT1P05V25C_CMAX | PASS | 24287 | 3.7344 | -0.3852 | 0 | 10.5490 |
| TT1P05V25C_CMIN | PASS | 24287 | 3.7720 | -0.3859 | 0 | 10.5670 |

각 코너의 BUSY–DONE VCD에서 실제 timescale과 측정 창을 읽어 SAIF를 새로 만들었습니다.
모든 코너에서 활동 감사가 통과했습니다. TX/TZ는 별도 기록하며 알려진 0으로 바꾸지 않습니다.
핀·net·포트 감사 레코드 수는 고유 신호 수나 기능 coverage 비율이 아닙니다.

기준형의 STA hold는 여전히 음수입니다. 따라서 common_power_eligible=false이며
qualified_worst_total_W=null입니다. 이는 제공 활동 연결 오류와 다른 항목입니다.
각 조가 공통 SDC를 완화하지 않고 hold를 보정해야 합니다.

SRAM memory 그룹의 SS/TT 음수 internal, 여섯 코너의 누설 0도 실제 보고서에서 재확인했습니다.
vendor 수치와 모든 매크로를 보존했습니다. 이는 교육용 모델 기반 pre-route 비교이며,
실제 SRAM 누설이 0이거나 signoff 전력이 검증됐다는 뜻이 아닙니다.

## 보존과 패치 검사

RTL·config·TB·ISA·주소·합성 Tcl·NDM 공용 절대경로·SDC·SDF 연결 코드는 v9.3과 같습니다.
패치는 팀 RTL·config·mapped 결과 보존, 재실행의 멱등성, 수정 파일 충돌 시 중단을 검사합니다.
활동 감사 회귀 검사 12건에는 다른 비트의 값, 실제 미주석 net, NC input 오면제,
라이브러리 시간 단위, TX/TZ, SDF 핀 경계 기록 등이 포함됩니다.
PDK·학생 메일·개인 설계·대용량 VCD를 공개 패키지에 포함하지 않습니다.
