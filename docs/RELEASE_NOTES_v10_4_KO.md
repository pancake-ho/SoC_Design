# EE470 v10.4

F12는 NPU DONE 이후 CPU가 공개 MMIO에서 읽어 커밋한 raw·Yq 1,568개를 골든과 대조합니다. 조별 SRAM 계층과 포트·폭·물리 배치는 팀 설계이며 별도 매핑 파일이 필요 없습니다.

공개 `project_top` 포트, 논리 주소·데이터 형식, 고정 F12 평가 벡터 및 측정용 리셋 해제–DONE의 시간·SAIF 구간을 사용합니다. 같은 RTL과 공통 포트 계약의 기존 mapped netlist·SDF로 새 테스트벤치를 다시 실행할 수 있습니다.

[F12의 공개 CPU commit 검사](F12_COMMIT_READBACK_KO.md)
