# EE470 v9.4.1 — ICG timing compatibility hotfix

2026-11-25. v9.4 SAIF 개정본에 적용하는 제공 측 시뮬레이션 정합성 수정입니다.

## 원인과 변경

- SAED32 CGLPPRX2_RVT의 FF 코너에서 SE 하강 setup 약 48 ps와 hold 약 −50 ps의 합이 음수입니다. VCS가 이를 유효한 combined timing-check window로 표현하지 못해 WSUM을 냅니다. 정상 SE=0 동작에서도 모델 경고가 생길 수 있습니다.
- 단순 SDF 출력 정밀도 문제로 끝나지 않습니다. 고정 회로의 clock uncertainty만 0.1 ns에서 0.3 ns로 바꾼 DC 실험에서도 SDF 지연·검사 레코드 12개는 동일했습니다. Uncertainty를 높여 재합성하면 실제 경로 여유를 개선할 수 있으나 모델 수치 불일치나 annotation 누락을 직접 고치는 방법은 아닙니다.
- 원본 PDK·NDM·SDF·STA는 수정하지 않습니다. 실행용 SDF 사본에서 **역전된 CGLPPRX2 검사창만 더 엄격한 방향으로 복구**합니다. setup은 유지하고 hold만 증가시켜 2 ps 창을 만들며, 증가량이 5 ps를 넘으면 자동 통과시키지 않고 중단합니다. 1 ps 격자에서 창 내부의 검사 시점을 확보하기 위한 보수적 표현입니다.
- 확인한 FF 예제는 setup 48 ps 유지, hold −50→−46 ps입니다. CLK→GCLK 지연·배선 지연·기능 논리·notifier·실제 검사와 판정은 유지합니다. 정상인 SS/TT 검사창은 바꾸지 않습니다.
- 이 수정은 원래 Liberty의 물리적 재특성화가 아닙니다. 원본 특성화가 정확해졌다고 주장하지 않으며, 교육용 게이트 검증에서 잘못된 역전 창을 보수적으로 표현하는 호환 수정입니다.
- 각 실행의 icg_timing_audit.json과 gate summary에 원본·실행용 SDF SHA256, 인스턴스·핀·edge·column·변경량을 기록합니다. 알 수 없는 형식·불완전한 검사·범위를 넘는 불일치는 실패합니다. 다른 종류의 ICG 경고를 일괄 허용하지 않습니다.

## 변경하지 않은 조건

공통 SDC, 외부 포트, RTL·ISA·주소·벡터, SAIF 측정 구간과 감사 기준, 배점·마감은 유지합니다. timing violation, SDF annotation 누락, WSUM/NTCDNC를 숨겨 PASS로 바꾸는 코드는 없습니다. **Hold는 각 조가 공통 SDC를 완화하지 않고 해결해야 합니다.**

## 검증

biclab0의 Library Compiler에서 대상 ICG 원본 셀 본문을 바꾸지 않은 진단용 라이브러리를 컴파일했습니다. 전체 PDK 재검증이나 재특성화가 완료됐다는 의미는 아닙니다. VCS에서 ICG 6코너·126개 실행, EN/SE×상승/하강 24개 코너별 위반 유형 검출, 창 밖 오검출 0, 정상 GCLK 파형 전후 일치를 확인했습니다. 기준형 SoC 게이트 F12도 6코너 각각 24,287 checks·기능 오류 0·SDF annotation/WSUM/NTCDNC 경고 0입니다. 원래 baseline의 STA hold는 여전히 음수여서 공식 성능 자격은 false로 유지됩니다. 학생별 최적화 SoC 전체를 새로 모두 실행한 결과는 아닙니다.

## 적용

동일 RTL·mapped netlist·원본 SDF를 재사용할 수 있어 **이 패치만으로 재합성은 필요하지 않습니다.** v9.4 SAIF 패치가 먼저 필요합니다. 패치 후 게이트 --saif를 다시 실행하고 그 새 gate run으로 power_saif.py를 실행합니다. 실행 명령은 ICG_TIMING_KO.md를 참고하세요. v9.1 reset 수정 전 합성 결과는 해당 수정과 재합성이 먼저 필요합니다.
