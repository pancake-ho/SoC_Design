# v9 변경 사유와 기존 작업 이전

## 변경 이유

기존 4×4 입력·필터 1개·출력 4개는 동작 이해에는 적합하지만, 전체 데이터가 작아
캐시·패킹·라인 버퍼·재사용에 따른 메모리 비용 차이가 충분히 드러나지 않았습니다.
공식 workload를 16×16 단일 채널 입력·3×3 필터 4개·출력 784개로 통일합니다.
MAC 수는 36에서 7,056으로 늘립니다. 합성되는 연산기는 반복 사용하는 구조로 유지합니다.
32×32·필터 8개보다 연산량을 약 9분의 1로 줄여 RTL·여섯 코너 검증 부담을 제한합니다.

## 학생이 배울 내용

- 필터 하나를 196개 출력 위치에 재사용하여 SRAM 읽기를 줄이는 방법.
- 인접 윈도우가 공유하는 입력 6개를 라인·윈도우 버퍼로 재사용하는 방법.
- 내부 INT8 패킹과 bank/address 선택 회로 사이의 면적·시간 절충.
- 부분합을 어디에 얼마나 보관할지 선택하고, MAC 병렬도와 데이터 공급 속도를 맞추는 방법.
- 기능 정확성, 절대 지연, 모든 코너 STA와 PPA를 같은 입력·경계에서 비교하는 방법.

## 함께 바뀐 계약

| 항목 | v8.1 | v9 |
|---|---|---|
| X/W/bias | 16/9/1 원소 | 256/36/4 원소 |
| raw/Yq | 각각 4개 | 각각 784개 |
| X/W/bias 시작 | 0x00 / 0x40 / 0x64 | 0x0000 / 0x0400 / 0x0490 |
| raw/Yq 시작 | 0x80 / 0x90 | 0x0600 / 0x1240 |
| CNN 요청 주소 | 6비트 word index | 11비트 word index |
| 기준 SRAM | IMEM 1 + DMEM 1 | IMEM 1 + DMEM 4 |
| F07 | 작은 프레임 100개 | 확장 프레임 12개 |
| NPU watchdog | 1,024 cycles | 262,144 cycles |
| profile / replay | v1 | v2 |

주소는 CNN DMEM의 논리 byte offset입니다. CPU MMIO 0x400·상수 창 0x600과 구분합니다.
CPU local은 CPU에서 0x00–0xFF이고 기준 DMEM 물리 word 320–383에 놓입니다.
CNN offset 0x0500–0x05FF는 예약되어 해당 접근을 거부합니다.
외부 project_top 포트·Harris 13개 ISA·수치 규칙·조별 제출·평가 비중·마감은 유지합니다.
CPU 내부 최적화와 SRAM 크기·뱅크 수·연산용 내부 패킹은 계속 자유입니다.

## 적용 방법

1. 기존 팀 작업 전체를 별도 보존합니다. v8.1 위에 새 압축본을 덮어쓰지 않습니다.
2. 새 폴더에 v9 전체 압축본을 풀고 제공 baseline으로 F01과 F03을 먼저 실행합니다.
3. 팀 RTL 변경을 새 rtl/에 이식합니다. CPU 최적화도 13개 ISA를 유지합니다.
4. X/W/bias 순서, 11비트 주소, 필터·행·열 반복 제어, raw/Yq 주소, watchdog을 새 계약에 맞춥니다.
5. 공식 model/·tb/·config/·scripts/와 공통 SDC는 v9 버전을 사용합니다. 예전 vectors.hex·snapshot은 재사용하지 않습니다.
6. F01–F12 전체와 추가 seed를 실행하고 새 netlist·SDF·PPA를 생성합니다. 이전 합성 결과·SDF·순위와 섞지 않습니다.

```bash
tar -xzf /path/to/EE470_Project_Baseline_20261119_v9.tar.gz
cd baseline_release
bash scripts/run.sh --case F01
bash scripts/run.sh --case F03
bash scripts/run.sh --suite public --replay-f07 tb/vectors/F07_seed470.json
```

## 메모리 최적화 설명에 포함할 수치

기본 입출력과 bias는 word32 저장 시 4,320바이트이며 INT8 밀집 저장 시 1,092바이트입니다.
필수 raw 결과 3,136바이트, CPU local, 정렬·버퍼·뱅크 제어 비용은 별도입니다.
raw는 최종 INT32 검증 결과입니다. 모든 단계의 부분합을 전체 배열로 저장하라는 뜻이 아닙니다.
기준형 8KiB DMEM을 그대로 사용해도 되고 더 작은 매핑이나 추가 뱅크를 사용해도 됩니다.
타일링·이중 버퍼링은 선택적 심화입니다. 특정 MAC 개수나 특정 캐시 구조를 강제하지 않습니다.
