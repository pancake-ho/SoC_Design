# 공개 인터페이스와 reference profile

기존 수업의 `project/shared/rtl/project_top.v` 포트 계약을 그대로 유지했습니다.
`clk`, active-low `rst_n`, `host_valid/host_write/host_addr/host_wdata`, `host_ready/host_rdata/host_error`,
`start/boot_addr`, `busy/done/trap`, `commit_valid/commit_pc/commit_insn/commit_rd/commit_wdata`,
8비트 `reserved_in`, `reserved_out`, `rp_aux_in0`~`rp_aux_in6`,
`rp_aux_out0`~`rp_aux_out6`입니다. RP는 Reserved Port입니다. 입력 8개·출력 8개, 포트당 8비트입니다.
기존 `reserved_in/out`의 비트 의미를 유지합니다. `rp_aux_in*`는 공식 TB에서 0으로 구동하고, 확장 출력은 기준형에서 0으로 연결합니다. 확장 포트에 추가한 로직도 area·energy에 포함합니다.
공개 `project_top` 포트를 유지합니다. 내부 Harris 데이터패스에는 SRAM 응답을 기다리기 위한 `step_en`을 연결합니다. 출처와 변경점은 [provenance](CORE_PROVENANCE.json)에 있습니다.

## CPU와 host

명령은 `add sub and or slt addi andi ori slti lw sw beq jal`입니다.
레지스터 x0만 0이며 다른 레지스터와 SRAM의 초기값은 보장하지 않습니다. reset 동안 쓰기는 금지됩니다.
기본 CPU는 Harris 데이터패스를 쓰고 SRAM 요청·응답에 필요한 대기 사이클을 둡니다. 각 명령의 실행·갱신은 한 번입니다.
13개 명령은 모두 필수입니다. CNN에 쓰이지 않는 명령도 F01에서 실제로 실행합니다. 공통 포트·ISA·commit 계약을 만족하는 CPU 내부 최적화는 가능합니다.
`commit_valid`는 실행 중 실제 명령이 완료되는 rising edge에만 1이며 stall에는 0입니다. PC/명령/rd/값을 프로그램 순서대로 한 번씩 보고하고 store의 효과도 한 번만 발생시킵니다. 지연이 있는 저장소는 읽기 데이터가 유효할 때까지 CPU 내부에서 기다립니다.

host는 CPU 정지 중에 접근합니다. 상승 에지에서 valid && ready이면 응답을 수락합니다. ready가 올라올 때까지 host는 valid와 주소·방향·쓰기 데이터를 유지합니다.
0x10000~0x103FF는 전용 IMEM SRAM의 256워드 적재·읽기 창입니다. CPU fetch는 PC[9:2]로 같은 IMEM을 읽습니다. CPU 데이터 포트는 IMEM에 접근하지 않습니다.
0x000~0x0FF는 CPU local DMEM 창입니다. CPU lw/sw와 정지 중의 host가 이 창을 사용합니다. CNN·MMIO 전송의 DMEM 영역은 별도로 매핑합니다.
0x20000~0x200FF는 상수 ROM 초기화·읽기 창입니다. host는 CPU와 같은 local/MMIO 주소로 데이터에 접근합니다.
`start`는 PC=0에서 CPU를 실행합니다. `boot_addr!=0`은 trap입니다.
CPU가 local 0xF0에 기록하면 실행이 끝납니다. PASS=0x600D, FAIL=0x0BAD입니다.
`jal x0,0` 자체는 HALT가 아닙니다. 테스트벤치 watchdog도 별도로 동작합니다.
CPU 통합 시험에서는 host가 실행 도중 MMIO나 SRAM을 대신 쓰지 않습니다.

## 데이터 주소

| 범위 | 내용 |
|---|---|
| 0x000~0x0FF | local DMEM 64×32-bit 동기 읽기·쓰기 |
| 0x400~0x41F | 아래 MMIO 8개 레지스터 |
| 0x600~0x6FF | CPU 데이터 경로의 64×32-bit 상수 ROM |

| 주소 | 이름 | 동작 |
|---|---|---|
| 0x400 | NPU_CTRL | WO: bit0 START, bit1 CLEAR; 읽기 0 |
| 0x404 | NPU_STATUS | RO: bit0 BUSY, bit1 DONE, bit2 ERR |
| 0x408 | CONFIG | RW: bit0 RELU_EN, bit1 SATFINITE, bits7:4 SHIFT. bits3:2 예약. reset=0x23 |
| 0x40C | SRAM_ADDR | RW: byte offset 전체 32비트로 검사 |
| 0x410 | SRAM_WDATA | RW: 32-bit |
| 0x414 | SRAM_CMD | WO: bit0 READ, bit1 WRITE, bit2 CLEAR |
| 0x418 | SRAM_STATUS | RO: bit0 BUSY, bit1 DONE, bit2 ERR |
| 0x41C | SRAM_RDATA | RO: 마지막 성공 READ 값; WRITE로 바뀌지 않음 |

CONFIG 외 상태/레지스터 reset 값은 0입니다. 예약 비트 읽기는 0, RO 쓰기는 무시합니다.
START는 CONFIG를 저장하고 DONE/ERR를 지웁니다. 완료는 마지막 SRAM write response 이후입니다.
BUSY 중 START/CONFIG 쓰기는 ERR를 세우고 현재 계산은 계속합니다. BUSY 중 CLEAR는 무시합니다.
CPU 전송 중 새 명령/주소/데이터 쓰기는 거부합니다. NPU BUSY 중 CPU SRAM 명령도 거부합니다.
정상 전송은 BUSY=0,DONE=1이며 응답 오류/timeout은 BUSY=0,DONE=0,ERR=1입니다.
READ/WRITE 동시 1, 비정렬, 0x1FFF 초과 또는 0x0500–0x05FF 예약 영역 주소는 SRAM 요청을 만들지 않습니다. 상위 비트를 잘라 alias시키지 않습니다.
idle CLEAR와 새 요청이 함께 오면 clear 후 요청을 검사합니다. START와 CPU 전송이 경쟁하면 START를 우선합니다.
CPU 전송 timeout은 16 cycles, NPU timeout은 262144 cycles입니다. reset은 현재 계산과 미완료 응답을 취소하고 SRAM 내용은 지우지 않습니다.

## SRAM 및 CNN

기준 RTL의 내부 CNN 메모리는 word 주소와 단일 outstanding의 valid/ready 요청·응답 포트를 사용합니다. 이 포트, 응답 사이클, 내부 물리 뱅크는 기준 구현의 선택입니다.
공개 SRAM 주소는 byte offset입니다. CNN/MMIO에서 CPU 예약 word 320..383에 접근하지 않습니다.

| SRAM byte offset | 내용 |
|---|---|
| 0x0000~0x03FC | Xq 256개, row-major. low8 signed INT8, upper24=0 |
| 0x0400~0x048C | Wq 36개, filter-major, 필터별 3×3 row-major. low8 signed INT8 |
| 0x0490~0x049C | 필터별 bias signed32, 4워드 |
| 0x0600~0x123C | ReLU 전 최종 raw 784개, signed32 |
| 0x1240~0x1E7C | Yq 784개, filter→row→column, low8 signed INT8·upper24=0 |

X[16][16]·W[4][3][3]·bias[4]에서 raw/Yq[4][14][14]를 계산합니다. index=f*196+r*14+c입니다.
공통 TB가 지정 주소·형식으로 입력을 적재하고 F12 CPU가 START와 전체 출력 읽기를 수행합니다. 공식 검사기는 DONE 이후 CPU LW의 값을 공개 commit으로 비교합니다. SRAM 래퍼의 포트·계층과 레지스터 파일 계층은 팀이 결정합니다. INT8 입력 워드 상위 24비트는 0이며 실행 중 공통 입력을 보존합니다.

유효 START를 한 번 수락하면 NPU가 CONFIG를 보관하고 메모리 읽기, 연산, 결과 쓰기를 자체 제어합니다.
파이프라인 깊이, PE 배치·병렬도, FSM, 내부 캐시·패킹은 팀이 정합니다. 개별 결과에 3사이클 제한을 두지 않습니다.
공개 포트·주소·형식·오류 동작을 지키며 지정 주소에서 전체 결과를 읽을 수 있을 때 DONE을 올립니다.
F12는 초기 리셋 → 공개 host를 통한 입력과 프로그램 적재 → 측정용 리셋 → CPU START 순서입니다. 측정용 리셋에서 적재 내용을 보존합니다. 평가 시간은 이 리셋 해제부터 유효 DONE까지입니다.

예를 들어 Xq[0]이 −7이면 host를 통해 SRAM_ADDR(0x40C)에 0x0000, SRAM_WDATA(0x410)에 0x000000F9, SRAM_CMD(0x414)에 WRITE를 기록합니다. DUT가 이 논리 주소를 실제 물리 SRAM 뱅크와 word에 대응시킵니다. TB는 내부 계층에 쓰지 않습니다.
공통 입출력은 1864워드입니다. CNN 창 0x0000–0x1FFF 안에서 고정 입출력과 CPU 예약 0x0500–0x05FF를 제외한 정렬 워드는 임시 사용이 가능합니다.
연산용 내부 패킹, 추가 메모리, 뱅크와 인덱스 배치는 자유입니다. 모든 구현에서 공통 입출력 주소와 데이터 형식을 지킵니다.

입력/필터 signed INT8, product signed16, bias를 더한 정확한 합의 공개 형식은 signed32입니다.
출력 위치마다 bias와 9개 곱의 정확한 합을 구한 뒤 한 번만 INT32로 변환합니다.
signed33이면 가능한 모든 중간 합을 표현할 수 있습니다. 중간 합이 범위를 넘었다가 돌아오면 최종 합을 그대로 사용합니다.

| CONFIG[1] | signed32 변환 |
|---|---|
| 1 (리셋 기본값) | SATFINITE. 정확한 합을 [-2147483648, 2147483647]에 포화 |
| 0 | wrap. 정확한 합의 하위 32비트를 signed two's complement로 해석 |

예를 들어 2147483647+1은 포화 시 0x7FFFFFFF, wrap 시 0x80000000입니다.
변환한 raw를 저장하고 같은 raw로 ReLU·반올림·INT8 포화를 수행합니다. 두 모드 모두 결과를 쓴 뒤
`BUSY=0, DONE=1, ERR=0`으로 정상 완료합니다. ERR는 프로토콜·메모리 오류나 timeout에 사용합니다.
SHIFT=2와 ReLU on에서 `0x23`은 포화, `0x21`은 wrap입니다. START 수락 시 선택을 저장합니다.
필터를 뒤집지 않는 cross-correlation이며 출력마다 bias를 한 번 더합니다.
SHIFT=0..15, half tie는 0에서 먼 쪽, ReLU 후 반올림·INT8 포화 순서입니다.
Python `round()`나 음수 `>>>`만으로 대체하지 않습니다. ONNX bit-exact 규칙이라고 표시하지 않습니다.

기준형은 `SRAM1RW512x32`를 IMEM 1개·DMEM 4개 사용합니다. CPU local 0x00–0xFF는 DMEM 물리 word 320..383에 매핑하며 CNN 논리 영역에서 예약합니다. IMEM·DMEM 접근 경계를 유지하며 SRAM 용량·뱅크 수·내부 배치를 선택할 수 있습니다.
공식 합성에는 공급 라이브러리에서 simulation/DB/NDM 뷰가 일치하는 실제 SRAM을 사용합니다.
사용한 매크로 전체와 추가 메모리·뱅크 제어 로직을 모두 PPA에 포함합니다.
`reserved_in[3:0]`은 응답 추가 지연, bit4는 응답 오류, bit5는 응답 누락, bit6은 ready stall입니다.
실측 PPA에서는 이 입력을 0으로 고정하고 해당 회로를 임의로 제외하지 않습니다.
`reserved_out[3:0]`은 transfer ERR, NPU ERR, DONE, BUSY 순서입니다. 상위4비트는 0입니다.

NPU는 각 필터별 bias와 9개 곱을 누산합니다. baseline은 최종 raw·Yq 한 쌍을 쓴 뒤 다음 출력으로 진행합니다. 모든 부분합의 전체 배열 저장은 요구하지 않습니다.

NPU의 개별 요청에서 진행이 없으면 기준형은 32 cycles에 오류를 냅니다. 전체 실행 한도 262144와 CPU 전송 한도 16을 구분합니다.

## 공개 타이밍 조건

`clk`의 주기는 조별로 선택합니다. 공개 `clk`의 나머지 속성, `rst_n` 계약, 포트와 신호의 의미, 입력 delay·transition·출력 delay·load, clock uncertainty는 [공통 타이밍 조건](../synth/README_KO.md)을 따릅니다. 내부 NPU 클록과 내부 경로는 팀 SDC에서 기술합니다.
