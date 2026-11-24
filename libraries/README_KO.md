# dice 공용 NDM

수업 계정으로 dice에서 합성을 시작하면 `synth/library_setup.tcl`이 다음 두 NDM을 읽기 전용으로 참조합니다.

| 라이브러리 | 절대경로 |
|---|---|
| SAED32 RVT 표준셀 | `/home/soc/common/saed32_ndm_20261112/full_pvt/saed32_rvt_ss_tt_ff.ndm` |
| SAED32 SRAM | `/home/soc/common/saed32_ndm_20261112/full_pvt/saed32_sram_ss_tt_ff.ndm` |

두 NDM 모두 SS·TT·FF를 포함합니다. 개인 폴더에 복사하거나 경로를 설정할 필요가 없습니다.
작업용 `work/design.nlib`과 결과는 각 팀의 `synth/` 작업 사본에 생성됩니다.
셀 종류는 [표준셀 카탈로그](catalog.html)에서 검색할 수 있습니다.
