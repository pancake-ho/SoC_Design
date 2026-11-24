# v9.2 게이트 타이밍 모델 수정 안내

## 무엇이 제공 환경의 문제였나요

WSUM과 NTCDNC는 데이터 경로의 실제 hold slack 위반과 다른 항목입니다.

- **SRAM WSUM:** 교육용 SAED32 SRAM에서 DC가 출력한 일부 setup+hold 합이 최저 −0.3 ps였습니다. 기존 연결 모델이 이 값을 그대로 VCS의 결합 검사에 넣어, VCS가 음수 값을 0으로 대체했습니다. 약 120 ps의 음수 setup 전체가 0이 되는 것은 의도한 검사창을 바꿉니다.
- **TT NTCDNC:** DFFSSRX1/2 모델에는 현재 SDF가 사용하지 않는 0폭 검사 자리표시자가 있습니다. 이 선언이 실제 상승 클록 setup/hold와 지연 신호를 공유하면서 VCS의 음수 타이밍 계산을 방해했습니다.

두 항목 모두 제공 모델 연결 코드에서 처리합니다. 학생이 SDC를 완화해서 해결할 항목이 아닙니다.

## 어떻게 고쳤나요

`synth/saed_sram_sdf.py`는 PDK와 DC 원본 SDF를 수정하지 않습니다. 실행 폴더에 만든 시뮬레이션용 사본만 조정합니다.

1. SRAM setup/hold 한계값을 현재 시뮬레이터의 1 ps 격자로 **큰 값 방향으로 올림**합니다. 음수 setup도 예를 들어 −122.7 ps → −122 ps이고 hold는 122.4 ps → 123 ps입니다. 검사창을 보수적으로 넓히며 각 값의 증가는 1 ps 미만입니다. 모든 변경 전후 값을 `model_timing_audit.json`에 기록합니다. setup+hold 불일치가 1 ps를 넘으면 자동 보정하지 않고 중단합니다.
2. DFFSSR의 0폭 자리표시자는 현재 SDF가 해당 선언을 사용하지 않는지 검사한 뒤 시뮬레이션 사본에서만 제외합니다. 실제 상승 클록 D/RSTB/SETB 검사, 출력 경로, notifier, 기능 논리는 유지합니다. 다른 SDF 검사 형태가 발견되면 중단합니다.
3. `+neg_tchk +overlap+new_solver`로 음수 검사창을 처리합니다. 타이밍 검사나 notifier를 끄는 옵션은 사용하지 않습니다.

원본 STA·SDF·mapped netlist·RTL·공통 SDC·NDM·포트·평가 조건은 그대로입니다. VCS가 경고와 함께 임의로 음수 한계값을 0으로 바꾸던 처리를 대신해 명시적인 검사값과 변경 기록을 남깁니다.

## 기존 v9.1 팀 작업에 적용

아래는 이미 v9.1 리셋 수정으로 재합성한 팀의 절차입니다. `baseline_release` 작업 폴더에서 실행합니다.

```bash
tar -xzf /path/to/EE470_Project_v9_2_Model_Timing_Fix_20261119.tar.gz -C .
python3 tools/v9_2/apply_model_fix.py --check
python3 tools/v9_2/apply_model_fix.py --apply
python3 synth/gate_timing.py
```

합성 결과를 다른 폴더에 만들었다면 마지막 명령을 다음처럼 바꿉니다.

```bash
python3 synth/gate_timing.py --synth-dir synth_v9_1
```

이 패치는 제공 게이트 실행기·모델 연결 코드와 안내만 교체하고, 이전 파일은 `patch_backups/v9_2_...`에 보관합니다. 학생 RTL과 합성 결과를 덮어쓰지 않습니다. **v9.1에서 올 때는 재합성이 필요 없고 게이트 실행만 다시 합니다.**

v9 또는 그 이전 사용자는 먼저 v9.1 동기식 리셋 수정과 재합성이 필요합니다. 새로 시작하면 v9.2 전체본을 사용하세요. 두 수정은 원인이 다릅니다.

## 결과를 읽는 법

- `functional_status`: TB가 결과값과 프로토콜을 통과했는가.
- `sdf_complete`: SDF 연결이 완료됐고 SDF annotation 경고가 없는가.
- `timing_model_warnings`: WSUM·NTCDNC가 남았는가. v9.2 기준형의 여섯 시나리오는 빈 목록입니다.
- `timing_violation`: 실행한 벡터에서 실제 시뮬레이션 타이밍 위반이 있었는가.
- `sta_pass`: 그 시나리오의 setup과 hold STA가 모두 통과했는가.

기준형은 모델 경고가 해결돼도 STA hold 위반이 남으므로 `all_scenarios_qualified=false`입니다. 학생은 `set_fix_hold`와 데이터 경로 최적화로 hold를 보정하고 자기 netlist·SDF를 재검증합니다. 공통 I/O delay·uncertainty·load·예외를 바꾸지 않습니다. 게이트 한 벡터가 통과해도 모든 경로의 hold가 검증된 것은 아닙니다.
