# EE470 프로젝트 v10.4 테스트벤치

## F12 검증 순서

1. 초기 리셋 후 테스트벤치가 `project_top`의 공개 호스트 포트에서 Xq·Wq·bias부터 전송합니다. 이어 출력 sentinel, IMEM 프로그램과 CPU 상수를 적재합니다.
2. 측정용 리셋을 한 번 더 인가합니다. 공통 논리 주소의 미리 적재한 값을 보존합니다. 측정 시작점은 이 `rst_n` 상승의 실제 ps 시각입니다.
3. CPU를 한 번 실행합니다. CPU는 CONFIG를 쓰고 MMIO START를 한 번 실행합니다. NPU는 메모리 읽기·연산·저장을 자체적으로 진행하며 내부 연산 사이클 수는 고정하지 않습니다.
4. RTL과 게이트 모두 공개 top 포트의 host 응답, CPU commit, NPU 상태와 호스트 읽기 결과로 검사합니다. 내부 신호명과 요청 수, SRAM 응답 클록, NPU 파이프라인 깊이는 팀이 정합니다.
5. NPU DONE 상승 후 CPU가 지정 논리 주소의 결과를 SRAM_RDATA로 읽습니다. TB는 공개 CPU commit에서 raw 784개와 Yq 784개를 각각 대조합니다. CPU checksum·signature와 입력 보존도 검사합니다. [F12 공개 LW 검사](F12_COMMIT_READBACK_KO.md)

`execution_time_ps = output_valid_ps − workload_reset_ps`입니다. TB의 적재와 후속 정답 대조는 측정 구간 밖입니다. 리셋 해제 후 DUT가 수행하는 데이터 이동·패킹·연산·결과 저장은 시간과 SAIF에 포함합니다. 공개 CORE_CLK 에지로부터 DONE까지의 오프셋 및 BUSY–DONE은 진단용입니다.

## 실행과 결과

```bash
bash scripts/run.sh --case F12 --macro
bash scripts/run.sh --suite public --macro
(cd synth && bash run.sh)
python3 synth/gate_timing.py --saif
python3 synth/power_saif.py --gate-run GATE_RUN_DIR
```

`GATE_RUN_DIR`에 실제 출력 경로를 넣습니다. `case_result.json`의 `npu_timing`에서 경계를 확인합니다. `gate_timing_summary.json`은 `qualified_worst_execution_time_ps`, `power_summary.json`은 `qualified_worst_energy_J`를 보고합니다. 리셋 해제–DONE의 DUT 활동으로 계산한 `energy_J = total_W × duration_ps × 10⁻¹²`를 각 시나리오에서 확인합니다.

게이트는 `synth/outputs/timing_run.txt`의 실제 외부 클록 주기를 사용합니다. 여기에는 팀 SDC에서 지정한 주기도 반영됩니다. RTL에서 같은 주기를 재현하려면 `--clock-period-ps`를 지정하세요. 고정 리셋과 입출력 조건은 [합성 안내](../synth/README_KO.md)를 따릅니다.

## 랜덤 연습과 비트 고정 평가

연습용 F12는 실행할 때마다 signed INT8 입력과 필터, bias를 새로 생성합니다. 각 실행 폴더의 `vectors/vectors.json`에 실제 입력값과 seed가 저장됩니다. `--seed`로 다시 생성하거나 `--replay-f12`로 동일한 실물 벡터를 재사용할 수 있습니다.

교수자는 평가할 F12 snapshot 하나를 선정해 모든 조에 동일한 파일과 `vector_sha256`을 적용합니다. 현재 패키지에는 평가 비트를 지정하지 않았습니다. 평가할 때는 다음처럼 실행합니다.

```bash
bash scripts/run.sh --case F12 --macro --replay-f12 PATH_TO_VECTORS_JSON
python3 synth/gate_timing.py --saif --replay-f12 PATH_TO_VECTORS_JSON --evaluation-sha256 INSTRUCTOR_SHA256
python3 synth/power_saif.py --gate-run GATE_RUN_DIR
```

F12의 입력 비트와 golden 결과를 포함한 canonical `vectors.hex`가 지정된 SHA256과 일치해야 평가용으로 기록합니다. 랜덤 연습은 성능과 에너지 진단에 사용할 수 있습니다.

`reserved_in/out`은 기존 상태·오류용이며 `rp_aux_in0`부터 `rp_aux_in6`, `rp_aux_out0`부터 `rp_aux_out6`는 확장용입니다. 입력 8개와 출력 8개이며 각 포트가 8비트입니다. 공식 시험에서는 확장 입력을 모두 0으로 구동합니다.
