# IDEC CNN 가속기 RTL

IDEC 제출 RTL을 기능별 SystemVerilog 모듈로 분리했습니다. 합성 또는 상위 설계에 연결할 때 top module은 `cnn_accelerator_top`입니다. 배포본 루트를 기준으로 `rtl/sources.f`의 소스 순서와 include 경로를 적용합니다.

## 수정할 파일 찾기

| 기능 | 파일 |
|---|---|
| 외부 I/O를 코어에 연결 | `rtl/cnn_accelerator_top.v` |
| 단계 전환과 하위 모듈 연결 | `rtl/cnn_inference_core.sv` |
| 픽셀 수집, 7행 버퍼, Conv1 6×6 sliding window | `rtl/core/conv1_input_window.sv` |
| Conv1 양자화·max-pool·ReLU, Conv2 입력용 feature-map ring | `rtl/core/conv1_quantize_pool.sv` |
| Conv2 진행 제어, 2개 입력 채널 누산, 양자화·pooling | `rtl/core/conv2_accumulate_pool.sv` |
| 10개 FC 점수, argmax, 완료 pulse | `rtl/core/fc_score_argmax.sv` |
| Conv1·Conv2·FC의 요청 선택과 tag 구성 | `rtl/core/engine_request_scheduler.sv` |
| 공유 엔진의 pipeline 연결 | `rtl/engine/shared_shift_add_engine.sv` |
| P0–P2 입력 capture와 transform | `rtl/engine/input_tile_transform.sv` |
| P2–P3의 49-lane 병렬 처리와 lane별 비트폭 | `rtl/engine/shift_add_lane_array.sv`, `rtl/engine/lane_bit_widths.svh` |
| lane 공통의 signed shift-add와 weight 선택 | `rtl/engine/shift_add_lane.sv` |
| lane별 모델 계수 | `rtl/engine/conv_coefficient_table.svh`, `rtl/engine/fc_coefficient_table.svh` |
| P4–P6의 Conv inverse transform, FC reduction, 응답 | `rtl/engine/output_transform_reduce.sv` |
| 입력 파일·bias 포트 연결, 요청·점수·완료 검사 | `tb/tb_cnn_inference.sv`, `tb/cnn_test_weights.svh`, `tb/cnn_test_scoreboard.svh` |
| 공유 엔진과 제출 엔진의 cycle별 비교 | `tb/tb_shared_engine_equivalence.sv` |

편집할 엔진 RTL은 5,104줄에서 연결부 45줄과 기능별 블록으로 분리했습니다. 49개 lane은 같은 모듈을 인스턴스화합니다. 계수 파일의 24비트 항목은 `{signed12 coeff0, signed12 coeff1}`이고, 첫 번째 채널 또는 class 0 항목이 각 행의 최하위 word입니다.

## 인터페이스와 시점

[원본 RTL] `rst_n`은 active-low synchronous reset입니다. 이미지마다 reset을 적용한 다음, reset 해제 후 첫 rising edge는 priming에 사용합니다. 그 다음 rising edge부터 row-major 순서의 784개 unsigned 8-bit 픽셀을 연속 입력합니다. 이 인터페이스에는 입력 `valid`·`ready` 포트가 없습니다.

공유 엔진은 한 cycle에 요청 하나를 받을 수 있습니다. `req_valid`를 샘플한 edge에서 6개 clock interval 뒤에 `rsp_valid`가 올라옵니다. `req_is_fc`가 FC와 Conv를 구분합니다. Conv의 `req_tag[15]`는 Conv1/Conv2, `[11:8]`과 `[7:4]`는 pooled row/column, `[3:2]`와 `[1:0]`은 출력/입력 채널입니다. FC는 `[3:0]`을 class로 사용합니다.

Conv1 요청을 우선하고, 필요한 Conv1 값이 ring에 기록되면 Conv2 요청을 발행합니다. Conv2의 48번째 pooled 값이 기록된 뒤 FC를 시작합니다. 마지막 FC 응답을 소비한 edge에서 `decision`이 갱신되고 `valid_out_6`가 한 cycle 동안 올라옵니다. 동일 점수에서는 먼저 처리한 낮은 class index가 선택됩니다.

`w_*` 포트는 기존 연결 호환을 위해 포함되어 있습니다. 가속기는 RTL의 고정 계수로 연산하며 `b_1`, `b_2`, `b_fc`를 실제 bias 입력으로 사용합니다.

## 실행

Python 3.9 이상과 Verilator 5.x(`--timing`), C++ 빌드 도구가 필요합니다. 루트에서 실행하면 빌드와 로그가 `build/` 아래에 생깁니다.

```bash
python3 scripts/run_simulation.py rtl --images 10
python3 scripts/run_simulation.py rtl
python3 scripts/run_simulation.py original
python3 scripts/run_simulation.py engine
```

`rtl`은 wrapper까지 연결해 기준 예측값·FC 점수·요청 수·완료 cycle을 검사합니다. `original`은 제출 RTL을 별도로 빌드합니다. `engine`은 원본 엔진과 모듈화 엔진을 같은 clock에서 구동해서 응답과 49개 lane의 P3 결과를 비교합니다.

Vivado 환경에서 `xvlog`, `xelab`, `xsim`이 PATH에 있으면 아래 명령으로 실행할 수 있습니다. Windows에서는 설치 환경에 맞게 `python3` 대신 `python`을 사용합니다.

```bash
python3 scripts/run_simulation.py rtl --sim xsim
python3 scripts/run_simulation.py engine --sim xsim
python3 scripts/run_simulation.py gls --sim xsim
```

`gls`는 원본 ASAP7 netlist와 cell 모델로 zero-delay 기능 검사를 실행합니다. 기존 Vivado 프로젝트 설정은 `original/vivado_project/`에 보관했습니다. 배포본에서는 위 실행 스크립트가 현재 폴더를 기준으로 파일 경로를 구성합니다.

## 검증 결과

[실험 관찰] Verilator로 원본과 모듈화 RTL을 각각 실행했습니다. 상세 로그는 `verification/`에 있습니다.

| 검사 | 확인 결과 |
|---|---|
| 이미지 예측 | 원본 및 모듈화 RTL 각각 기준 예측 1,000/1,000 일치 |
| FC 점수 | 원본 및 모듈화 RTL 각각 10,000/10,000 bit-exact 일치 |
| 이미지 완료 | 1,000개 모두 첫 픽셀 capture를 cycle 1로 셌을 때 cycle 836에서 완료. 두 edge 사이 간격은 835 cycles |
| 이미지당 요청 | Conv1 288개, Conv2 96개, FC 10개 |
| 제출 이미지 라벨 기준 정확도 | 원본 및 모듈화 RTL 모두 990/1,000 |
| 공유 엔진 비교 | 수락 3,726개 중 유효 응답 3,716개 일치. 처리 중 reset으로 10개 취소. P3 유효 벡터 3,722개의 49개 lane 일치 |

이번 검증은 위 벡터에 대한 2-state RTL 시뮬레이션입니다. Vivado·GLS·신규 합성·STA/PPA는 미실행입니다. `original/synthesis/`의 netlist·SDC·리포트는 원본 제출 RTL의 산출물입니다.

## 자료 범위와 EE470 연결

`original/`에 제출 RTL과 TB, ASAP7 cell 모델, netlist, SDC, 리포트를 포함했습니다. 제출본에는 기능별 파일명만 적용했고 파일 내용과 내부 식별자는 보존했습니다. `data/` 및 `reference/`에는 제출 이미지 1,000개, weight·bias 입력, 예측·점수 기준값이 들어 있습니다. `original/tb/submitted_engine_oracle_tb.sv`의 별도 oracle 파일과 `original/tb/submitted_independent_inputs_tb.sv`의 독립 입력 세트는 제출 ZIP에 없었습니다. 기본 테스트는 동봉한 데이터와 자체 엔진 비교 벡터를 사용합니다. 학습 코드와 RTL 생성기 원본은 제출 ZIP의 범위 밖입니다.

[EE470 사양] `EE470_Project_Spec_RISCV_SRAM_CNN_KO_v8.docx` §6은 SRAM에서 signed INT8 4×4 입력과 3×3 필터를 읽어 2×2 raw 및 Yq를 기록하는 CNN을 요구합니다. 이 ZIP의 IDEC CNN은 28×28 픽셀에서 10-class `decision`을 출력하는 fixed-model RTL입니다. EE470 팀에서 재사용할 부분은 공통 lane, 데이터 공급, pipeline 분할의 구현 방식입니다. EE470의 동적 weight, SRAM 주소, 수치·제어 계약을 적용하는 통합 작업은 별도입니다.
