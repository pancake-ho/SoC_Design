## 2026-11-25 v9.4.2 ICG SDF 호환 수정

[변경점·검증·적용 방법](docs/RELEASE_NOTES_v9_4_2_KO.md)

## 2026-11-25 v9.4.1 ICG 호환 수정

v9.4 SAIF 기준을 유지하면서 CGLPPRX2_RVT의 역전 timing-check window를 실행용 SDF에서 보수적으로 복구합니다. 재합성 없이 게이트·SAIF 전력을 다시 실행합니다. 공통 SDC와 학생의 hold 보정 책임은 유지합니다. [변경점](docs/RELEASE_NOTES_v9_4_1_KO.md), [적용 방법](docs/ICG_TIMING_KO.md).

# v9.4 게이트 SAIF 활동 연결 수정

배열 비트 활동 오매핑과 실제 미연결 출력 핀의 판정 오류를 수정했습니다.
전체 측정 조건과 공통 SDC는 유지하며 hold는 각 조가 해결합니다.
적용·실행 방법은 [SAIF 안내서](docs/POWER_SAIF_KO.md), 변경점은
[v9.4 릴리즈 노트](docs/RELEASE_NOTES_v9_4_KO.md)를 확인하세요.
같은 v9.3 설계와 기존 --saif VCD를 보관했다면 전력만 다시 실행할 수 있습니다.

---

# v9.3 SAIF 전력 측정 개정

게이트 SDF로 기능·실제 지연을 확인한 뒤, 같은 F12의 NPU BUSY–DONE 활동으로
CPU·모든 SRAM·NPU를 포함한 project_top의 전력을 여섯 코너에서 계산합니다.
기존 RTL·ISA·포트·메모리 계약·입력 크기·공통 SDC·배점은 유지합니다.
자세한 실행 방법과 자격 기준은 [POWER_SAIF_KO.md](docs/POWER_SAIF_KO.md)에 있습니다.

```bash
python3 synth/gate_timing.py --saif
python3 synth/power_saif.py --gate-run synth/gate_timing_실제경로
```

STA hold가 남아 있으면 gate 실행의 종료 코드는 1일 수 있습니다. 여섯 gate_status가
모두 PASS인 경우 전력 진단은 가능하지만 공식 PPA 자격은 false입니다.
hold는 각 조가 데이터 경로에서 보정하며 공통 SDC를 완화하지 않습니다.
재합성 여부는 RTL 변경 여부로 판단합니다. 동일 v9.2 설계는 기존 netlist·DDC·SDF를
재사용할 수 있지만 SAIF 활동을 저장하는 게이트 실행은 새로 필요합니다.

---

# EE470 RISC V SRAM CNN 프로젝트 v9.2

16×16 단일 채널 입력과 3×3 필터 4개를 계산하는 완성된 느린 시작 예제입니다.
같은 784개 출력을 유지하면서 데이터의 저장·이동·재사용을 개선하고 실제 지연과 PPA로 설명합니다.
[변경 사유와 이전 방법](docs/MIGRATION_V9_KO.md) · [릴리즈 노트](docs/RELEASE_NOTES_KO.md) · [고정 계약](docs/API_CONTRACT.md)

## v9.2 모델 경고 수정

SS/TT의 WSUM·NTCDNC를 제공 모델 연결 코드에서 수정했습니다. [적용 방법](docs/MODEL_TIMING_FIX_KO.md)과 [실제 재검증 결과](docs/VALIDATION.md)를 확인하세요. 여섯 시나리오 게이트 F12와 SDF 연결은 모두 통과했고 모델 경고는 0개입니다. STA hold 보정은 별도이며 공통 SDC는 바꾸지 않습니다. v9.1 합성 결과는 재사용할 수 있습니다.

## v9.1 게이트 리셋 수정 이력

게이트 F12의 X/timeout을 유발한 제공 합성 흐름을 수정했습니다. [적용 방법](docs/GATE_RESET_FIX_KO.md)을 따라 반드시 재합성합니다. 실제 여섯 시나리오의 F12는 전부 오류 0이며 hold/model 경고와 별도로 기록합니다.

## 왜 입력을 늘렸나요

이전 4×4·필터 1개는 36 MAC에 그쳐 메모리 재사용 효과를 비교하기 어려웠습니다.
v9는 7,056 MAC으로 늘리되 32×32·필터 8개보다 연산량을 약 9분의 1로 제한합니다.
기준 RTL은 MAC 하나를 반복 사용합니다. 원소 수만큼 연산기나 FF 배열을 생성하지 않습니다.
각 필터는 196개 위치에서 재사용되며 인접 윈도우는 입력 6개를 공유합니다.
패킹·필터 캐시·라인 버퍼·타일링·병렬 MAC은 선택입니다. 사용한 모든 저장소와 제어 로직을 PPA에 포함합니다.

## 계산과 데이터 순서

X[16][16], W[4][3][3], bias[4]에서 raw[4][14][14], Yq[4][14][14]를 만듭니다.
stride=1, padding=0, 필터를 뒤집지 않는 cross-correlation입니다.
출력 순서는 filter → row → column이며 index=f*196+r*14+c입니다.
signed INT8 입력·가중치, 필터별 signed INT32 bias, 정확한 signed33 합을 사용합니다.
최종 합에서 INT32 포화(기본) 또는 wrap을 적용한 뒤 기존 ReLU·rounding·INT8 포화를 수행합니다.

## 고정 입출력 메모리

아래는 CPU 주소 공간이 아니라 SRAM_ADDR 레지스터에 쓰는 CNN DMEM 바이트 오프셋입니다.
입력 INT8은 한 워드의 low8에 하나씩 저장하며 상위24비트는 0입니다. 내부 패킹은 자유입니다.

| 시작~마지막 워드 주소 | 워드 수 | 내용 |
|---|---:|---|
| 0x0000–0x03FC | 256 | X, row-major |
| 0x0400–0x048C | 36 | W, filter-major |
| 0x0490–0x049C | 4 | 필터별 bias |
| 0x0600–0x123C | 784 | raw, signed32 |
| 0x1240–0x1E7C | 784 | Yq low8, 상위24비트 0 |

논리 창은 0x0000–0x1FFF입니다. 0x0500–0x05FF는 CPU local 전용이므로 CNN/MMIO 접근을 거부합니다.
그 외 비입출력·비예약 영역의 임시 사용과 추가 저장소는 자유입니다.
기준형은 IMEM SRAM 1개와 DMEM SRAM 4개를 사용합니다. 각 매크로는 SAED32 SRAM1RW512x32입니다.

## 실행

baseline_release에서 실행합니다. 이전 주차처럼 run.sh 명령을 사용합니다.

```bash
bash scripts/run.sh --case F01
bash scripts/run.sh --case F03 --waves
bash scripts/run.sh --suite public --replay-f07 tb/vectors/F07_seed470.json
```

학생 추가 벡터는 tb/student/example.json의 X 256개, W 36개, bias 4개 형식을 따릅니다.
F07은 12개 확장 프레임입니다. 포화·wrap × 양·음 overflow를 각각 최소 한 프레임씩 보장합니다.
나머지 8개 슬롯에는 기본 5% 확률로 overflow를 추가합니다. seed·snapshot·SHA256을 고정해 팀 간 일관되게 비교합니다.
곱 9개만으로 INT32 overflow가 나지는 않으므로 INT32 한계에 가까운 bias를 의도적으로 생성합니다.

## CPU 통합과 성능

F01은 CNN과 별개로 Harris 13개 필수 명령을 모두 실제 실행합니다.
F12는 TB가 공통 포트로 입력을 적재한 뒤 CPU가 CONFIG·START·polling·전체 raw/Yq 읽기와 checksum 확인을 수행합니다.
TB는 checksum 외에도 모든 1,568개 raw/Yq 워드를 독립 golden과 직접 비교합니다.
큰 입력을 위한 상수 ROM 확장을 피하고, CPU의 실행과 NPU 제어를 분리해 확인하는 구성입니다.

NPU 처리 한도는 262,144 cycles, CPU MMIO SRAM 전송 한도는 기존 16 cycles입니다.
기준형은 메모리 접근에 진행이 없으면 32 cycles에 오류로 중단합니다. 정상 응답 지연은 0–15 cycles입니다.
결과의 cnn_cycles·cnn_reads·cnn_writes로 연산 시간과 논리 메모리 접근을 비교합니다.
내부 캐시·뱅크 접근 수는 팀이 추가 계측해 구분합니다. 이 논리 카운터를 실제 SRAM 전력으로 환산하지 않습니다.
시작 전에 계산·정답·필터 연산을 미리 수행하여 BUSY–DONE 비용을 숨기지 않습니다.

## 합성과 게이트 검증

```bash
cd synth
bash run.sh
cd ..
python3 synth/gate_timing.py
```

SAED32 표준셀·SRAM NDM은 기존 /home/soc/common/saed32_ndm_20261112/full_pvt/ 절대경로를 직접 참조합니다.
DC NXT Topographical 단계까지이며 Fusion place-and-route는 요구하지 않습니다.
동일 mapped netlist의 SS/TT/FF × CMAX/CMIN 여섯 시나리오에서 setup·hold를 검사합니다.
클록 주기는 EE470_CLK_PERIOD_PS, ideal source latency는 EE470_CLK_LATENCY_PS로 설정합니다.
공통 I/O delay·uncertainty·load·예외를 수정해 위반을 숨기지 않습니다. set_fix_hold와 합성 최적화를 활용합니다.
SDF 측정 시간은 Δcycle×period + DONE pin offset − BUSY pin offset입니다.
NTCDNC·WSUM 등 timing check 완화 경고가 있으면 MODEL_CHECK_WARNING으로 기록하여 완전한 타이밍 검증과 구분합니다.
검증 완료 범위와 알려진 제한은 docs/VALIDATION.md에 명시합니다.
