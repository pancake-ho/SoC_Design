# 평가 기준

| 항목 | 전체 과목 성적 비중 |
|---|---:|
| Base core 프로그램 실행 정확성 | 10% |
| 필수 module/port 이름과 실제 SRAM 통합 | 10% |
| STA-clean 설계 사이의 PPA 상대평가 | 10% |
| CNN 독창성·창의성 | 5% |
| PPA를 고려한 구조 선택과 근거 | 5% |
| AI 사용 방법과 직접 검증 기록 | 5% |

프로젝트 합계 45%, 중간고사 45%, 출석 10%입니다. 임의의 프로젝트 100점 배점으로 바꾸지 않습니다.
Power/Performance/Area 측정값과 순위는 각각 별도이며 임의 가중합·P×P×A 점수를 만들지 않습니다.
미확정 환산 가중치·동점 후 성적 처리·개인 기여 계수는 적용하지 않고 `grade=null`입니다.
기본 순위 운영안은 competition ranking(1,1,3)입니다.

BASE와 INTEGRATED는 별도 비교 집합입니다. BASE는 CPU·SRAM·NPU가 포함된 `project_top`의
같은 mapped netlist에서 주기를 sweep해 6개 시나리오의 setup·hold를 모두 만족한 최고 검증 주파수(MHz)를 보고합니다.
INTEGRATED의 공통 성능 비교는 10 ns의 `BUSY`–`DONE` 구간입니다. CPU 준비를 포함한 전체 시간은 보조 지표입니다.
더 짧은 검증 주기의 결과는 별도로 보고합니다. SDF 측정이 유효하면 핀 간 절대 지연은
`cycle 차이 × 주기 + DONE 핀 지연 − BUSY 핀 지연`으로 기록합니다.

공식 SDC의 클록·latency·I/O delay·uncertainty·transition·load·예외를 그대로 적용합니다.
팀별 합성 설정, 데이터 경로 버퍼링과 게이트 크기 변경으로 hold를 보정할 수 있습니다.

CPU 내부 최적화는 선택이며 F01에서 Harris 13개 명령의 기능을 모두 통과하는 것이 필수입니다. CNN 실행에 사용하지 않는 명령도 유지합니다.
SS·TT·FF 각각 CMAX·CMIN에서 임계 경로 시작점·끝점, 절대 데이터 경로 지연(ns), setup·hold worst slack(ns)을 보고합니다.
더 짧은 주기를 별도로 보고하면 모든 시나리오가 통과한 공통 주기와 그 주기를 제한한 시나리오를 함께 명시합니다.

모든 제공 PVT에서 setup·hold가 모두 통과하고 STA error·unresolved cell·unconstrained path가 없어야 합니다.
음수 slack을 네 자리 표시에서 반올림해 숨기지 않습니다. 도구의 VIOLATED 판정은 그대로 실패입니다.
SRAM 종류·용량·뱅크 수·추가 버퍼는 자유입니다. 모든 물리 SRAM 인스턴스의 전체 면적과 동작 전력을 셉니다.
뱅크 제어, 주소 매핑, 패킹 해제 등 구현 로직도 포함하고 report_area 포함 범위를 확인해 중복 합산하지 않습니다.
동일 workload·corner·clock·측정 구간과 검증된 activity coverage·실제 macro power 모델이 필요합니다.
없는 수치나 미실행 결과는 null이며 0점 측정값이나 rank 1로 바꾸지 않습니다.

peer review는 통합 동작·독창성·PPA 선택·AI 활용 근거의 검토 자료입니다.
추가 배점·공지하지 않은 자동 감점 계수는 없습니다. 자기 팀은 제외하고 팀별 같은 수의 검토를 배정합니다.


## SAIF 전력 근거

v9.3부터 공통 F12 seed 470의 첫 NPU_BUSY 상승부터 DONE 상승까지 게이트 활동을 사용합니다.
CPU·SRAM·NPU 전체를 포함한 project_top에서 각 SDF 코너의 활동을 해당 라이브러리로 계산합니다.
입력 적재·리셋·출력 덤프와 TB 자체는 제외하며, idle 패딩을 하지 않습니다.
각 코너의 internal·switching·leakage·total power와 duration·energy를 별도로 제출합니다.
여섯 코너 total power의 최댓값도 요약하되 기존 배점과 세 지표별 상대평가는 유지합니다.
기능·SDF·STA setup/hold 및 activity annotation 검토가 끝나지 않은 값은 진단값으로 표시합니다.
공식 자격 미달의 qualified 값은 null입니다. 미주석 항목·모델 누락을 0이나 임의 toggle로 숨기지 않습니다.


### v9.4 활동 검토 보완

raw missing 숫자만으로 판정하지 않습니다. 실제 연결 net의 비트별 activity를 SAIF와 대조하고,
NC output만 coverage에서 제외합니다. 셀 자체의 internal·leakage는 포함합니다.
연결된 신호의 누락·잘못 매핑된 비트·기능/STA 실패는 계속 자격 미달입니다.
SRAM 모델의 음수 internal·누설 0 한계를 표시하고, 같은 라이브러리의 원본 전체 modeled total을
제출합니다. 기존 배점과 공통 SDC는 바꾸지 않습니다.
