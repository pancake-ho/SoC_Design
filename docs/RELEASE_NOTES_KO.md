# EE470 프로젝트 v9.2 릴리즈 노트

2026년 11월 19일

## 제공 타이밍 모델의 WSUM·NTCDNC 수정

SRAM의 sub-ps setup/hold 수치와 DFFSSR의 SDF 미사용 0폭 선언을 제공 연결 코드에서 처리했습니다.
이는 학생 설계의 STA hold 위반과 다른 문제입니다. 변경 전후 한계값과 제외한 선언을 실행 폴더에 기록합니다.

- SRAM 한계값은 시뮬레이션 사본에서만 1 ps 격자로 보수적 올림하며, 각 값당 증가는 1 ps 미만입니다.
- 실제 SDF 검사를 지우지 않고 미사용 0폭 자리표시자만 검사 후 제외합니다. 타이밍 검사와 notifier는 켜 둡니다.
- 원본 SDF·netlist·RTL·공통 SDC·NDM·STA와 workload·평가·마감은 그대로입니다.
- 여섯 시나리오 F12는 각각 24,287 checks·오류 0, WSUM=0, NTCDNC=0, SDF annotation 경고 0입니다.
- 정상·허용 입력 3종은 위반 0, 의도한 DFF/SRAM 위반 3종은 각각 검출해 검사 동작을 확인했습니다.
- STA hold 위반은 남으며 팀이 보정합니다. all_scenarios_qualified는 false입니다.

v9.1 사용자는 팀 작업용 v9.2 패치를 적용하고 게이트만 다시 실행합니다. 원본 합성 결과를 재사용할 수 있습니다.
v9.1의 동기식 리셋 수정이 없는 사용자는 해당 수정과 재합성이 먼저 필요합니다.
자세한 절차는 MODEL_TIMING_FIX_KO.md, 실제 결과는 VALIDATION.md를 참조하세요.

## 이전 릴리즈 이력

# EE470 프로젝트 v9.1 릴리즈 노트

2026년 11월 19일

## 게이트 F12의 X와 timeout 수정

제공 합성 흐름에서 동기식 reset이 일반 조합 논리와 합쳐지면서 gate 초기 X를 제거하지 못한 문제였습니다.
NPU state[0]의 X가 BUSY와 SRAM 요청으로 전파됐습니다. 학생이 해결해야 할 hold 위반과 별개입니다.

- 실제 reset 사용 모듈에 `// synopsys sync_set_reset "reset"`을 표시합니다.
- analyze/compile 전에 `compile_seqmap_honor_sync_set_reset=true`, `compile_restructure_sync_set_reset=false`를 적용합니다.
- 동기식 reset 방식, 초기값 계약, 기능 RTL, 공통 SDC, 외부 포트와 workload는 유지합니다.
- 새 합성 netlist와 여섯 SDF로 게이트 F12를 다시 실행하여 전 시나리오 24,287 checks·오류 0을 확인했습니다.
- RTL F01–F12와 SS/CMAX 게이트 F01·F10도 통과했습니다.
- 기능 결과·SDF 적용·timing-model 경고·STA 자격을 결과 JSON에서 따로 기록합니다.

**반드시 재합성합니다. 기존 netlist·SDF를 재실행하는 것만으로 고쳐지지 않습니다.**
팀 작업을 유지하는 패치 방법은 [GATE_RESET_FIX_KO.md](GATE_RESET_FIX_KO.md), 실제 결과는 [VALIDATION.md](VALIDATION.md)에 있습니다.
공통 SDC는 바꾸지 않았으며 hold는 팀별로 보정합니다. SS/TT timing-model 경고는 별도 기록하며 최종 timing 자격은 아직 false입니다.
새 입력 크기·주소·양자화·평가·마감 조건은 v9와 동일합니다.

## v9의 workload 개정 이력

# EE470 프로젝트 v9 릴리즈 노트

2026년 11월 19일

## 변경 사유

이전 4×4 입력·필터 1개·36 MAC은 메모리 재사용의 효과를 비교하기에 너무 작았습니다.
16×16 입력·3×3 필터 4개·7,056 MAC으로 확장하여 같은 데이터의 반복 읽기, 내부 패킹,
필터·윈도우 버퍼와 병렬 연산기의 데이터 공급 문제를 실제로 비교하도록 했습니다.
32×32·필터 8개의 64,800 MAC보다 연산량을 약 9분의 1로 제한하고 기준형 연산기는 하나를 반복 사용합니다.
이번 버전은 동일 결과를 더 효율적으로 저장·이동·계산하는 설계 선택을 배우기 위한 개정입니다.

## 주요 변경

- 입력 256개, 가중치 36개, 필터별 bias 4개. raw와 Yq는 각각 784개.
- 고정 CNN 오프셋: X 0x0000, W 0x0400, bias 0x0490, raw 0x0600, Yq 0x1240.
- filter → row → column 순서. index=f*196+r*14+c. 입력은 기존 word32 형식, 내부 패킹은 자유.
- 11비트 내부 논리 주소와 기준형 4-bank DMEM. IMEM은 별도 실제 SRAM 경로 유지.
- 최종 결과 하나씩 계산·기록하여 raw 784개를 FF 배열로 보관하지 않음.
- NPU 전체 한도 262,144 cycles. CPU 전송 한도는 기존 16 cycles. 무응답 요청을 별도 감시.
- F01–F12·학생 추가 벡터·정답 생성기·주소/alias 검사·CPU 통합 프로그램을 모두 동기화.
- F07을 확장 프레임 12개로 조정. 포화/wrap의 양/음 overflow 4범주와 재현 가능한 snapshot v2 보장.
- CPU가 전체 결과를 읽고 checksum 확인. TB는 checksum과 별개로 모든 raw/Yq 워드의 정답을 검사.
- cnn_reads와 cnn_writes를 함께 기록. gate 파형은 --waves를 지정할 때만 저장하여 실행·디스크 부담 제한.
- gate 판정에서 SDF 적용과 NTCDNC/WSUM timing-model 경고를 분리. 경고를 숨겨 완전한 timing PASS로 처리하지 않음.

## 유지되는 조건

project_top 외부 포트, Harris 13개 필수 ISA, signed/포화/wrap/양자화 규칙, CPU 최적화 허용,
SRAM 용량·뱅크·내부 패킹 자유도, 공용 절대 NDM 경로, 여섯 코너, 공통 I/O·uncertainty·load,
set_fix_hold 등을 통한 hold 보정, 조별 제출·평가 비중·15주차 화요일 마감은 유지합니다.
사용한 SRAM·버퍼·매핑 회로는 모두 PPA에 포함합니다. Fusion P&R는 요구하지 않습니다.
클록은 기존 매크로/환경변수로 설정하며 ideal source latency를 적용합니다.
절대 실행 시간은 Δcycle*period + DONE pin offset − BUSY pin offset으로 계산합니다.

## 실제 확인한 범위

dice의 교강사 계정에서 VCS V-2023.12-SP2-1과 실제 SAED32 SRAM 모델을 사용했습니다.
독립 수학 모델 32프레임, F07 snapshot replay, 공개 F01–F12가 통과했습니다.
최종 공개 전체 suite 실측 46.56초, 기준 NPU 프레임 105,840 cycles·14,896 logical reads·1,568 writes입니다.
DC NXT V-2023.12-SP5의 동일 PVT NDM 교강사 미러에서 6시나리오 합성을 실측 267.01초에 완료했습니다.
배포본은 기존 학생용 /home/soc/common/ 절대경로를 유지합니다. 이번 실행은 학생 계정의 재검증이 아닙니다.
기준형은 IMEM 1개·DMEM 4개, 총 5개의 실제 SRAM 매크로를 유지했습니다.
서버 부하·팀 구조에 따라 실행 시간은 달라집니다.

## 알려진 제한과 최종 자격

기준 설계에는 여섯 시나리오의 hold 위반(약 −0.3180~−0.4365 ns)이 남아 있습니다.
SDF 적용 실행은 수행했으나 게이트 F12가 X 상태/transfer_watchdog으로 실패하여 유효한 BUSY–DONE 절대 지연을 얻지 못했습니다.
일부 셀 timing check의 NTCDNC/WSUM 경고도 별도로 기록합니다. 기능 PASS나 합성 완료는 gate timing PASS를 뜻하지 않습니다.
기준형의 PPA 자격은 false이고 최종 절대 지연은 null입니다. 팀별로 hold 보정과 재검증을 수행합니다.
timing-model 경고 때문에 한계값이 완화된 실행은 완전한 검증으로 인정하지 않고 교강사에게 로그를 문의합니다.

## 이전 방법

v8.1 위에 덮어쓰지 말고 새 v9 폴더에 팀 RTL 최적화를 이식합니다.
새 주소 폭·반복 범위·출력 순서·timeout을 반영하고 공식 harness/profile/vector v2를 사용합니다.
이전 netlist·SDF·PPA는 새 workload와 혼용할 수 없습니다.
자세한 순서는 docs/MIGRATION_V9_KO.md에 있습니다.
