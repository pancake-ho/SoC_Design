# v9.3 릴리즈 노트

2026년 11월 21일

## 왜 바꾸나요

기존 배포본에는 SDF 게이트 기능·지연 검증이 있었지만 실제 활동을 전력 분석으로 연결하는
공통 실행 단계가 없었습니다. 전력 비교가 서로 다른 toggle 가정이나 측정 구간에 좌우되지
않도록 실제 SAIF와 DC NXT Topographical 전력 계산을 연결했습니다.

## 주요 변경

1. `gate_timing.py --saif`: 여섯 SDF 코너의 F12 DUT 활동을 저장합니다.
2. `power_saif.py`: BUSY–DONE 창을 VCD ticks로 변환해 SAIF를 생성하고 DURATION을 검사합니다.
3. 같은 mapped DDC의 여섯 코너에서 read_saif·report_saif·report_power를 실행합니다.
4. W·J 단위 결과, 계층·coverage·netlist/SDF/vector hash와 공식 자격을 JSON으로 기록합니다.
5. 한글·영문 명세서에 측정 목적·방법·범위·주의점을 추가합니다.

RTL·포트·ISA·메모리 입력/출력·랜덤/overflow 벡터·공통 SDC·평가 배점은 바꾸지 않습니다.
동일 RTL의 v9.2 사용자는 재합성하지 않아도 됩니다. 기존 mapped.v·DDC·SDF·STA를 보존하고
패치 후 `--saif` 게이트 실행과 전력 계산을 새로 수행하세요.
hold는 각 조가 보정합니다. 공통 SDC 완화나 timing check/notifier 비활성화는 허용하지 않습니다.
실제 실행 결과와 남은 제약은 POWER_VERIFICATION_KO.md에 기록합니다.
