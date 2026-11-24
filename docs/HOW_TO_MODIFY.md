# v9 구조 개선 방법

먼저 README와 API_CONTRACT를 읽고 F01·F03을 실행합니다. 전체 이전은 MIGRATION_V9_KO를 따릅니다.
rtl/에서 실제 동작을 수정합니다. starter/rtl도 동작 가능한 같은 시작 예제입니다.
단계별로 1) serial multiply 개선, 2) 필터 재사용, 3) 입력 윈도우 재사용, 4) 내부 패킹을 비교할 수 있습니다.
구조와 순서는 선택입니다. 각 변경의 cycle·논리 read/write·추가 버퍼·PPA를 동일한 workload로 기록합니다.
내부 물리 접근 횟수를 추가 계측한 경우 공통 관측 경계의 논리 접근 수와 따로 표기합니다.
데이터가 커졌다고 7,056개의 MAC을 조합 for-loop로 전개하지 않습니다. 반복은 FSM/counter로 여러 사이클에 수행할 수 있습니다.
공식 model·TB·timeout·SDC를 바꾸어 점수를 얻지 않습니다. TB가 내부 accumulator·FSM 이름에 의존하도록 바꾸지 않습니다.
