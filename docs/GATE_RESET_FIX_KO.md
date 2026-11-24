# v9.1 게이트 리셋 초기화 수정

## 원인

이 오류는 학생이 고쳐야 할 hold 위반과 별개의 제공 합성 흐름 문제였습니다.
기존 기준형의 게이트 netlist에서 리셋 중 NPU state[0]의 D가 X로 남았습니다.
이를 받은 상태 레지스터가 초기화되지 않아 BUSY, SRAM 요청, pending과 응답 상태까지 X로 오염됐고 F12가 timeout으로 끝났습니다.
SDF를 제거한 진단과 타이밍 검사를 끈 진단에서도 같은 증상을 재현했습니다.
이 진단 실행은 원인 분리용이며 공식 통과 결과로 사용하지 않습니다.

리셋이 일반 조합 논리와 합쳐져 재수렴한 부분은 실제 0/1 값에 대해서는 동작하지만,
초기 X를 가진 게이트 시뮬레이션에서는 X가 사라지지 않을 수 있습니다.
모듈 경계 최적화만 끄는 시험으로는 해결되지 않았습니다.

## 수정 내용

동기식 리셋의 의미를 합성기에 명확히 전달하고 보존합니다. 리셋을 비동기식으로 바꾸지 않습니다.

```verilog
// synopsys sync_set_reset "reset"
always @(posedge clk) begin
    if (reset) begin
        // 기존 reset 값 유지
    end else begin
        // 기존 동작 유지
    end
end
```

위 표시는 실제 동기식 reset을 사용하는 모듈에 적용합니다. reset이 없는 register file에는 넣지 않습니다.
공통 합성 스크립트의 analyze/compile 이전 설정은 다음과 같습니다.

```tcl
set_app_var compile_seqmap_honor_sync_set_reset true
set_app_var compile_restructure_sync_set_reset false
```

DC V-2023.12-SP5의 해당 옵션 매뉴얼은 동기식 set/reset을 레지스터 가까이에 유지해
X 전파로 인한 synthesis/simulation 불일치를 줄이는 목적을 명시합니다.
기준형의 관련 상태 레지스터는 실제 SAED32의 동기 set/reset 셀로 매핑됩니다.
초기값 강제, force, initreg, 타이밍 검사 해제, SDC 완화는 수정 방법으로 사용하지 않습니다.

## 기존 v9 팀 작업에 적용

작업을 보존한 사본에서 패치 압축본을 풉니다. 아래 /path/to/는 실제 다운로드 경로입니다.
패치는 팀 RTL을 통째로 교체하지 않고 세 기준 모듈의 리셋 표시와 합성 옵션을 추가합니다.
변경 파일은 patch_backups/에 보존하며, 모듈 구조나 reset 이름을 바꾼 경우 자동 적용을 중단하고 수동 반영을 안내합니다.

```bash
tar -xzf /path/to/EE470_Project_v9_1_Gate_Reset_Fix_20261119.tar.gz -C .
python3 tools/v9_1/apply_sync_reset_fix.py --check
python3 tools/v9_1/apply_sync_reset_fix.py --apply
```

**기존 mapped netlist·SDF를 다시 시뮬레이션하는 것만으로 고쳐지지 않습니다. 반드시 재합성합니다.**
이전 합성 결과를 보존하려면 새 합성 폴더를 사용합니다.

```bash
mkdir synth_v9_1
cp synth/run.sh synth/topo_ndm.tcl synth/library_setup.tcl synth_v9_1/
cd synth_v9_1
bash run.sh
cd ..
python3 synth/gate_timing.py --synth-dir synth_v9_1
```

파형이 필요하면 --scenario 시나리오명 --waves를 추가합니다.
NDM은 기존 /home/soc/common/ 절대경로를 사용하며, SDC의 I/O·uncertainty·load·예외는 바꾸지 않습니다.
RTL 기능시험도 새 소스로 다시 실행합니다.

## 결과 구분

- functional_status: 원래 F12의 전체 입력 보존·raw 784개·Yq 784개·CPU signature·protocol·체크포인트 검사 결과.
- sdf_complete: 지연 back-annotation 상태.
- timing_model_warnings: NTCDNC/WSUM 등 별도 모델 경고. 숨기지 않고 기록합니다.
- sta_pass: 해당 시나리오의 setup 및 hold 결과.
- all_scenarios_qualified: 위 조건을 모두 만족하는 최종 자격. 기능 PASS만으로 true가 되지 않습니다.

hold 보정은 각 팀이 수행합니다. 모델 경고와 제공 실행 흐름 오류를 학생 설계 실패로 단정하지 않습니다.
실측 최종 결과는 v9.1 RELEASE_NOTES_KO.md와 VALIDATION.md를 함께 확인하세요.
16×16 입력·필터 4개, 주소표, 포화/wrap·양자화 규칙, 벡터와 평가·마감 조건은 v9와 같습니다.
