# 공개 시험 v9

모든 CNN 시험은 X[16][16], W[4][3][3], bias[4], raw/Yq[4][14][14] 계약을 사용합니다.
필터별 row-major 순서와 지정 주소의 전체 raw 784개·Yq 784개를 검사합니다.

| ID | 확인 내용 |
|---|---|
| F01 | 실제 IMEM SRAM, Harris 13개 ISA 전부, commit 독립 대조, x0·signed·음수 offset·BEQ/JAL·DMEM signature |
| F02 | 4-bank 경계를 포함한 활성 워드 alias 검사·마지막 READ·응답 타이밍·reset |
| F03 | 네 필터·전체 출력·ReLU on/off·X/W/bias 원본 보존 |
| F04 | 모서리·내부·마지막 위치 impulse와 필터별 비대칭 kernel로 방향·인덱스 확인 |
| F05 | INT8 경계, 최종 합 전에 overflow했다가 돌아오는 경우, 양·음 INT32 overflow의 포화/wrap |
| F06 | SHIFT 0/1/2/15·양/음 half tie·INT8 포화·ReLU |
| F07 | 확장 랜덤 12개, 포화/wrap × 양/음 overflow 4범주 보장, seed·snapshot·SHA256 |
| F08 | BUSY 중 START/CONFIG/SRAM 명령/CLEAR, 설정 snapshot과 기존 frame 지속 |
| F09 | 비정렬·0x2000 이상·상위 주소 비트·CPU 예약 영역·READ/WRITE 동시, 내용 보존 |
| F10 | 계산 중 reset·입력 SRAM 보존·연속 실행·stale 값 방지 |
| F11 | 응답 지연·오류·누락·ready stall·timeout·reset 후 회복 |
| F12 | 공통 포트 적재 후 CPU START 1회·polling·전체 raw/Yq 읽기·checksum·signature, TB 전체 golden 대조 |

F12의 CPU checksum은 빠른 프로그램 내 확인입니다. 정답 판정은 각 워드의 독립 golden 대조가 추가되므로 checksum 충돌로 PASS하지 않습니다.
TB는 입력을 적재할 뿐 CPU 실행 중 계산·MMIO 제어를 대신하지 않습니다.
기능 PASS는 compile·종료·SUMMARY·checks>0·errors=0·protocol_errors=0과 overflow 개수 대조가 모두 필요합니다.
기능 PASS·SDF 적용 완료·setup/hold clean·timing model warning 없음은 서로 다른 검사입니다.
