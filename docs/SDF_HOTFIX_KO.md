# 과거 v8.1 SDF 수정 이력

이 문서는 과거 버전 설명입니다. v9에 패치를 다시 적용하지 마세요. 현재 상태는 VALIDATION.md를 따릅니다.

# EE470 v8.1 SDF 수정 적용 안내

제공된 SRAM 모델의 타이밍 선언과 DC SDF의 연결을 수정했습니다.
기존 v8 작업 폴더에는 소형 패치를 적용하고, 새로 시작할 때는 v8.1 전체 압축본을 사용하세요.

## 기존 작업에 패치 적용

본인 baseline_release 폴더에서 패치 파일의 실제 다운로드 경로를 입력합니다.

~~~bash
tar -xzf /path/to/EE470_Project_v8_1_SDF_Hotfix_20261118.tar.gz -C .
python3 synth/gate_timing.py
~~~

이미 있는 synth/outputs/project_mapped.v, 여섯 시나리오 SDF와 STA 리포트를 사용합니다.
합성 결과가 아직 없으면 synth/에서 bash run.sh를 실행한 후 프로젝트 루트에서 위 명령을 실행하세요.

한 시나리오를 먼저 확인할 수도 있습니다.

~~~bash
python3 synth/gate_timing.py --scenario SS0P95V125C_CMAX
~~~

## 결과 읽기

출력의 GATE_RUN_DIR에서 gate_timing_summary.json을 확인합니다.

- sdf_complete가 true이면 지연 적용이 경고 없이 끝난 것입니다.
- gate_status는 F12 동작, 프로토콜, 체크포인트 측정값과 타이밍 위반을 종합한 시나리오별 결과입니다.
- sta_pass는 해당 시나리오의 setup·hold 리포트를 함께 확인한 결과입니다.
- all_scenarios_qualified는 여섯 시나리오의 STA와 게이트 검증이 모두 통과했는지 나타냅니다.
- 당시 v8.1 판정은 공통 10 ns·latency 0의 BUSY–DONE을 사용했습니다. 현재 조건과 결과 필드는 [v10.2 테스트벤치 안내](TESTBENCH_V10_KO.md)를 따릅니다.

각 시나리오 폴더에는 compile.log, simulation.log, sram_annotation.json이 생성됩니다.
원본 SDF 해시와 적용용 SDF 해시를 함께 보관해 보고서의 실행 근거로 사용하세요.
한 시나리오 진단 후에는 옵션 없이 재실행하여 전체 결과를 얻으세요.

## 수정 원리

SAED32 SRAM의 원본 기능 모델에는 DC SDF가 참조하는 CE → O와 OEB → O 경로 선언이 빠져 있었습니다.
실행 폴더에서 생성한 모델에 이 경로를 추가하고 SDF 지연값을 적용합니다.
SRAM setup·hold와 DFFAR reset recovery/removal은 검사 전용 내부 인스턴스에 연결합니다.
같은 CSB setup 조건이 중복되면 SDF의 각 열에서 더 엄격한 값을 사용합니다.

## 검증 범위

2026년 11월 17일 dice의 VCS V-2023.12-SP2-1에서 기준 설계의 여섯 시나리오가 모두 sdf_complete=true였습니다.
원본과 적용용 SDF의 IOPATH·INTERCONNECT를 시나리오별로 대조했습니다.
검증에 사용한 SRAM은 SRAM1RW512x32, reset cell은 DFFARX2_RVT입니다.
SS0P95V125C_CMAX의 SRAM CE → O[0] 지연은 178.8 ps였고, OEB 비활성화·활성화 지연은 170.7 ps·160.7 ps였습니다.
일부러 만든 SRAM setup 위반과 reset timing 위반도 검출했습니다.

기준 설계에는 기존 hold 위반과 F12 host_access_timeout이 남아 있습니다.
각 팀의 최종 성능은 해당 조의 netlist와 SDF로 재실행해 확인해야 합니다.
