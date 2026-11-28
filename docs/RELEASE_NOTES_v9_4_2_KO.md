# EE470 v9.4.2 ICG SDF 호환 패치

2026-11-25

FF 코너의 CGLPPRX2_RVT에서 일부 setup·hold 검사창이 역전돼 VCS가 WSUM을 보고했습니다. 실행용 SDF의 역전된 항목에만, 기존 setup 값을 기준으로 hold를 엄격한 방향으로 조정합니다. 검사창은 1 ps 격자에서 2 ps 이상을 확보합니다. 항목별 증가량은 최대 9 ps까지 적용하며, 이를 초과하는 SDF는 진단 오류로 중단합니다.

FF의 실제 MAX 열 예에서 setup은 8.6 ps이고 hold는 −15.0 ps입니다. 검사창 폭은 −6.4 ps였고, hold를 −6.0 ps로 조정하면 +2.6 ps가 됩니다. 9 ps는 이 항목에서 증가한 양입니다. 이번 패치는 게이트 시뮬레이션에 쓰는 SDF 호환 수정입니다. 원본 Liberty·SDC·STA·SDF와 CLK→GCLK 및 배선 지연, 타이밍 검사와 notifier를 보존합니다. 실행별 `icg_timing_audit.json`에 항목별 원값과 적용값이 기록됩니다.

| PVT·RC 시나리오 | 역전된 SDF 값 수¹ | 최대 hold 증가(ps) | VCS F12 |
|---|---:|---:|---|
| SS0P95V125C_CMAX | 0 | 0 | PASS |
| SS0P95V125C_CMIN | 0 | 0 | PASS |
| TT1P05V25C_CMAX | 0 | 0 | PASS |
| TT1P05V25C_CMIN | 0 | 0 | PASS |
| FF1P16VN40C_CMAX | 541 | 9 | PASS |
| FF1P16VN40C_CMIN | 550 | 9 | PASS |

¹ 한 검사창의 MIN·TYP·MAX 열을 각각 셉니다. VCS F12는 MAX 열로 실행했습니다. 106개 ICG의 실제 설계에서 시나리오마다 24,287 checks, 기능·프로토콜 오류 0건, SDF 주석 및 타이밍 모델 경고 0건을 확인했습니다. FF 두 시나리오의 MIN·MAX에서 가장 크게 보정한 항목은 창 안의 위반을 검출했고, 창 밖의 시험 전이와 원래 정상 GCLK 파형도 확인했습니다.

Setup uncertainty 0.200→0.209 ns와 hold uncertainty 0.100→0.109 ns를 같은 DDC 사본에 적용한 대조에서는 FF ICG SDF 검사값 변화가 0건이었습니다. Hold slack은 CMAX +6.086→−2.914 ps, CMIN +5.331→−3.669 ps였습니다. 공통 uncertainty에는 보정량을 합산하지 않습니다.

## 설계팀 제출 전 확인

모든 SS·TT·FF × CMAX·CMIN 시나리오에서 `check_timing`과 `report_constraint -all_violators`를 함께 확인하고, setup·hold 외에도 보고된 max capacitance, max transition, min pulse width, recovery/removal 등 실제 적용된 제약 위반을 모두 수정해 주세요. 위반의 원인에 맞춰 드라이버 크기, 버퍼 배치, fanout 등을 조정하고 설계를 수정한 경우 6개 시나리오를 다시 검사합니다. 공통 SDC의 값과 검사 적용 범위를 유지합니다. 게이트 F12 통과와 설계 제약 충족 여부는 각각 확인해 주세요.

## 기존 작업에 적용

현재 v9.4 또는 v9.4.1의 `baseline_release`에서 다음을 실행합니다. 합성 결과를 그대로 쓰는 경우 재합성 없이 게이트·SAIF를 재실행합니다. 회로를 변경해 전기적 제약 위반을 해결한 경우에는 새 합성 결과로 재검증합니다.

```bash
tar -xzf /path/to/EE470_Project_v9_4_2_ICG_Patch_20261125.tar.gz -C .
python3 tools/v9_4_2/apply_icg.py --check
python3 tools/v9_4_2/apply_icg.py --apply
python3 synth/gate_timing.py --saif
python3 synth/power_saif.py --gate-run /path/to/GATE_RUN_DIR
```
