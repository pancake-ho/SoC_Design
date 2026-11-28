# EE470 v10.2 변경사항

- 제출 클록은 조별로 선택합니다. 10 ns는 초기 예제값입니다. 제출 주기는 여섯 SS·TT·FF × CMAX·CMIN 시나리오에 일관되게 사용합니다.
- `synth/run.sh --sdc`로 팀 SDC를 읽습니다. 내부 NPU 클록, generated clock, 실제 CDC의 클록 관계와 타이밍 제약을 설계에 맞게 기술합니다. 사용한 SDC와 하위 파일을 함께 제출합니다.
- 공개 `clk`의 ideal 모델과 50% 듀티·위상 0·source latency 0, 리셋과 입출력 규약, 공통 uncertainty·transition은 유지합니다. 외부 포트의 이름·방향·폭·타이밍과 공개 주소 규약을 지킵니다.
- 합성이 기록한 실제 `CORE_CLK` 주기를 게이트와 SAIF 평가가 사용합니다. 같은 고정 F12와 같은 mapped netlist로 여섯 시나리오의 setup·hold, SDF 게이트, 활동 검증을 수행합니다.
- 각 조의 실측 reset–DONE 시간과 동일 구간의 에너지(J), 전체 mapped DUT 면적을 2:1:1로 평가합니다. 이전 DC 산출물은 보관하고 새 SDC로 재합성한 결과를 사용합니다.

설정 예제와 고정 수치는 [합성 안내](../synth/README_KO.md)에 있습니다.
