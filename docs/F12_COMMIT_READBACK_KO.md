# F12 결과를 공개 CPU commit으로 확인하기

1. 테스트벤치가 공개 호스트 포트로 입력과 프로그램을 적재한 뒤 측정용 리셋을 해제합니다.
2. CPU가 NPU START를 한 번 실행하고 NPU 상태에서 `DONE`을 기다립니다. 공식 시간과 SAIF 구간은 측정용 리셋 해제에서 공개 `reserved_out[1]` 상승까지입니다.
3. CPU가 `SRAM_ADDR`에 CNN 논리 바이트 주소를 쓰고 READ를 요청합니다. 성공한 응답마다 `lw x2, 28(x8)`로 `SRAM_RDATA`를 읽습니다. 기본 맵에서 `x8=0x400`이므로 읽는 주소는 `0x41C`입니다.
4. 테스트벤치는 공개 `commit_valid`, `commit_pc`, `commit_insn`, `commit_rd`, `commit_wdata`로 올바른 주소 순서에서 해당 LW가 완료됐는지 확인합니다. `0x0600`의 raw 784개와 `0x1240`의 Yq 784개를 독립 골든과 개별 비교합니다.

`x1`과 `x2`는 제공 시험 프로그램의 논리 레지스터입니다. 레지스터 파일의 계층 이름은 설계마다 달라도 됩니다. SRAM의 내부 계층·포트·주소 변환·뱅크·데이터 폭은 팀이 정하며 테스트벤치에 물리 매핑을 제공할 필요가 없습니다. 공개 주소와 데이터 형식, CPU 명령 및 `project_top` 포트는 공통 규약을 따릅니다.

F12에서 DONE이 한 번 올라온 뒤 정상 완료 상태에서 모든 LW가 순서대로 커밋되어야 합니다. 잘못된 값, X/Z, 누락, 중복 또는 조기 완료 펄스는 실패합니다. CPU checksum과 signature, 공개 호스트 읽기를 통한 입력 보존 확인도 수행합니다. 결과가 DONE 때 준비되어야 한다는 계약의 기능 판정은 DONE 이후 CPU의 읽기 응답을 관측합니다. 내부 SRAM 쓰기의 정확한 시각은 이 공개 검사에서 직접 확인하지 않습니다.

```bash
bash scripts/run.sh --case F12 --macro
python3 synth/gate_timing.py --saif
```

`case_result.json` 또는 `gate_timing_summary.json`의 `commit_readback`에서 확인 개수 `count`, 첫·마지막 LW 시각 `first_ps`·`last_ps`, 완료 신호 상승 횟수 `done_rises`를 확인합니다. 값 불일치가 있으면 로그에 `F12_LW_MISMATCH`와 논리 주소·예상값·관측값이 나옵니다.
