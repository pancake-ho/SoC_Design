# v9.3 SAIF 실제 검증 결과

2026년 11월 21일 biclab0의 임시 작업 폴더에서 VCS V-2023.12-SP2-1과
DC NXT Topographical V-2023.12-SP5로 실행했습니다. dice v9.2의 동일 mapped netlist·DDC·
여섯 SDF·공통 SDC를 사용했습니다. 검증 호스트의 임시 라이브러리 경로만 조정했습니다.
원본 PDK·도구 설치·학생 계정·공통 SDC는 바꾸지 않았습니다.

## 기능과 전력

| Scenario | F12 checks | errors | setup WNS ns | hold WNS ns | Total mW | Energy µJ |
|---|---:|---:|---:|---:|---:|---:|
| FF1P16VN40C_CMAX | 24287 | 0 | 5.0109 | -0.4315 | 167.1000 | 176.858623 |
| FF1P16VN40C_CMIN | 24287 | 0 | 5.0422 | -0.4319 | 167.1400 | 176.900959 |
| SS0P95V125C_CMAX | 24287 | 0 | 0.5755 | -0.3122 | 6.2557 | 6.621031 |
| SS0P95V125C_CMIN | 24287 | 0 | 0.6417 | -0.3133 | 6.2323 | 6.596264 |
| TT1P05V25C_CMAX | 24287 | 0 | 3.7344 | -0.3852 | 10.5680 | 11.185169 |
| TT1P05V25C_CMIN | 24287 | 0 | 3.7720 | -0.3859 | 10.5870 | 11.205279 |

모든 gate_status는 PASS, sdf_complete=true이며 protocol 오류·실행 중 timing violation은 0입니다.
BUSY–DONE은 105,840 cycles이며, 실제 핀 지연을 포함해 약 1.0584 ms입니다.
각 VCD의 100 fs tick을 읽어 1 ps 성능 체크포인트를 정확히 변환했습니다.
SAIF DURATION×TIMESCALE은 각 코너의 DONE−BUSY와 일치했습니다.
매핑 netlist SHA256은 `7d960e3ed4d03cade7160c6b6da5228aef329edf57264b5f321538edc0d5dc7c`입니다.

## 공식 자격과 분리해 읽어야 할 항목

기준형 STA hold는 모든 코너에서 음수입니다. 별도로 report_saif의 missing 목록에는
각각 ports 0·nets 1·pins 189가 남습니다. 최상위 포트는 100% user annotation이지만 이것만으로
모든 내부 활동의 검토가 끝난 것은 아닙니다. 일반 모드와 debug_access+all의 대조 실행에서도
동일한 누락 목록을 확인했습니다. 로그·계층 리포트로 별칭·미사용 핀·상수 여부를 검토해야 합니다.
이를 임의 toggle로 채우거나 숨기지 않았습니다.

따라서 이 수치는 **실행이 확인된 진단값**입니다. common_power_eligible=false,
qualified_worst_total_W=null을 유지했습니다. 학생에게 모든 STA와 활동 자격을 통과했다고
설명하지 않습니다. 각 조는 공통 SDC를 완화하지 않고 hold를 보정해야 합니다.

internal·switching·leakage·total은 서로 다른 단위가 섞이므로 각 열의 단위를 읽어 W로 변환합니다.
일부 SRAM 그룹의 internal 값은 음수이며 원본 값을 보존했습니다. 임의로 0으로 clamp하거나
그룹 숫자만으로 전체 소비전력을 해석하지 않습니다. 라이브러리의 분할 회계 방식과 전체 total을
함께 검토합니다. 음수 internal 값이 존재할 수 있다는 해석 자료는
[Cornell의 실제 Synopsys 도구 튜토리얼](https://cornell-ece5745.github.io/ece5745-tut5-asic-tools-2017sp/)입니다.
이 참조가 개별 SAED32 SRAM 모델의 signoff 정확성을 보증하는 것은 아닙니다.

## 검증 산출물 보관

SAIF 여섯 개, 원본 report_power·report_saif·명령·로그·raw 결과 등 102개 파일을 로컬로 가져와
해시를 대조했습니다. PDK 원문과 대용량 VCD를 배포 압축본에 포함하지 않습니다.
biclab0의 임시 프로젝트·라이브러리 사본은 결과 회수 후 삭제했습니다.
