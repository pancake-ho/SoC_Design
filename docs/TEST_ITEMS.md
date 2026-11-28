# 공개 시험 v10.1

모든 CNN 시험은 X[16][16], W[4][3][3], bias[4], raw/Yq[4][14][14] 계약을 사용합니다.
필터별 row-major 순서와 지정 주소의 전체 raw 784개·Yq 784개를 검사합니다.

| ID | 확인 내용 |
|---|---|
| F01 | 실제 IMEM SRAM, Harris 13개 ISA 전부, commit 독립 대조, x0·signed·음수 offset·BEQ/JAL·DMEM signature |
| F02 | 공개 주소 전 범위의 활성 워드 alias 검사·마지막 READ 데이터 보존 |
| F03 | 네 필터·전체 출력·ReLU on/off·X/W/bias 원본 보존 |
| F04 | 모서리·내부·마지막 위치 impulse와 필터별 비대칭 kernel로 방향·인덱스 확인 |
| F05 | INT8 경계, 최종 합 전에 overflow했다가 돌아오는 경우, 양·음 INT32 overflow의 포화/wrap |
| F06 | SHIFT 0/1/2/15·양/음 half tie·INT8 포화·ReLU |
| F07 | 확장 랜덤 12개, 포화/wrap × 양/음 overflow 4범주 보장, seed·snapshot·SHA256 |
| F08 | 호스트 SRAM 전송 충돌·기존 요청 보존·CONFIG 쓰기 수락 시 공개 NPU BUSY에 따른 결과 |
| F09 | 비정렬·0x2000 이상·상위 주소 비트·CPU 예약 영역·READ/WRITE 동시, 내용 보존 |
| F10 | START 이후 reset, 입력 SRAM 보존·연속 실행·stale 값 방지 |
| F11 | 응답 지연·오류·누락·ready stall·timeout·reset 후 회복 |
| F12 | 초기 리셋 후 입력 적재와 측정용 리셋 해제, CPU START 1회·polling·DONE 상승, 이후 공개 commit에서 raw·Yq의 LW 1,568개와 signature 확인 |

F12의 CPU checksum은 프로그램 안에서 확인합니다. 채점은 DONE 이후 공개 CPU commit의 각 LW 값과 논리 주소 순서를 독립 golden과 비교합니다.
F12 측정은 적재 후 측정용 `rst_n` 상승부터 `reserved_out[1]`의 정상 DONE 상승까지입니다. 사전 적재·후속 읽기·TB 활동은 에너지 구간 밖입니다. DUT 내부 메모리 구조와 요청·응답 사이클을 참조하지 않습니다.
TB는 입력을 적재할 뿐 CPU 실행 중 계산·MMIO 제어를 대신하지 않습니다.
기능 PASS는 compile·종료·SUMMARY·checks>0·errors=0·protocol_errors=0과 overflow 개수 대조가 모두 필요합니다.
기능 PASS·SDF 적용 완료·setup/hold clean·timing model warning 없음은 서로 다른 검사입니다.
