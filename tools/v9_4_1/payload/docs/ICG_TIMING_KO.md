# v9.4.1 ICG 패치 적용과 재실행

현재 작업 중인 v9.4 baseline_release 폴더에서 실행합니다. 팀 RTL과 합성 outputs는 지우지 않습니다. /path/to/는 내려받은 패치의 실제 위치로 바꿉니다.

```bash
tar -xzf /path/to/EE470_Project_v9_4_1_ICG_Patch_20261125.tar.gz -C .
python3 tools/v9_4_1/apply_icg.py --check
python3 tools/v9_4_1/apply_icg.py --apply
python3 synth/gate_timing.py --saif
```

첫 단계가 PATCH_CHECK_PASS일 때 적용합니다. 수정된 공통 파일이 발견되면 덮어쓰지 않고 중단하므로 그 파일을 먼저 검토합니다. 백업은 patch_backups/v9_4_1_*에 남습니다. 이미 적용됐으면 ALREADY_PATCHED가 나옵니다.

출력의 GATE_RUN_DIR 실제 경로를 사용하여 다음을 실행합니다.

```bash
python3 synth/power_saif.py --gate-run /실제로_출력된/GATE_RUN_DIR
```

## 볼 항목

- 각 코너의 gate_status=PASS, functional_status=PASS, sdf_complete=true와 timing_model_checks_complete=true를 확인합니다. 실제 위반은 계속 TIMING_VIOLATION입니다.
- icg_timing_audit.json은 변경 인스턴스와 한계값을 기록합니다. changes가 빈 목록이면 해당 코너에 보정이 필요한 CGLPPRX2 역전 창이 없었다는 뜻입니다.
- STA setup·hold가 남으면 sta_pass와 공식 자격은 false입니다. 게이트 기능 PASS를 공식 전체 통과로 해석하지 않습니다. baseline도 이 사유로 명령 종료 코드가 1일 수 있습니다.
- hold는 set_fix_hold 등 실제 경로 보정으로 해결합니다. 공통 SDC의 I/O delay·uncertainty·load·timing 예외를 완화하지 않습니다.
- RTL을 바꾸면 재합성이 필요합니다. 이 패치는 동일 설계의 게이트 모델 정합성만 바꿉니다.
- 이 수정은 CGLPPRX2_RVT에서 검증했습니다. 다른 셀·알 수 없는 SDF 형식·5 ps를 넘는 보정 요구는 경고를 무시하지 말고 로그와 함께 문의합니다.

## 원본 보존과 한계

원본 PDK·공용 NDM·DC SDF·STA·CLK→GCLK 지연은 유지합니다. 실행용 SDF의 잘못된 음수 폭만 더 엄격하게 보정합니다. 이는 Liberty의 트랜지스터 재특성화가 아니며 실리콘 signoff 모델 보증을 의미하지 않습니다. 검증용으로 사용한 컴파일러 기본 DDTC/DRTZ 메시지는 원문 로그에 남겼고, 모델 검사·annotation·실제 위반을 면제하는 새 판정 규칙은 추가하지 않았습니다.
