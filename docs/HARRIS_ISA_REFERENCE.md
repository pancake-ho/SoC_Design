# EE470 Harris 싱글 사이클 ISA 참조표

프로젝트는 Harris & Harris §7.6의 `RISCVsingle` 공개 HDL에 열거된 13개 RV32I 명령을 사용합니다. opcode는 instruction[6:0], funct3는 [14:12], R-type funct7은 [31:25]입니다. opcode와 funct7은 16진수입니다.

| 명령 | 형식 | opcode | funct3 | funct7 | 아키텍처 동작 |
|---|---|---|---|---|---|
| `add rd, rs1, rs2` | R | 0x33 | 000 | 0x00 | 두 레지스터의 합 하위 32비트를 rd에 기록 |
| `sub rd, rs1, rs2` | R | 0x33 | 000 | 0x20 | rs1−rs2 하위 32비트를 rd에 기록 |
| `and rd, rs1, rs2` | R | 0x33 | 111 | 0x00 | 두 레지스터의 비트별 AND |
| `or rd, rs1, rs2` | R | 0x33 | 110 | 0x00 | 두 레지스터의 비트별 OR |
| `slt rd, rs1, rs2` | R | 0x33 | 010 | 0x00 | signed(rs1) < signed(rs2)이면 1, 그 외 0 |
| `addi rd, rs1, imm` | I | 0x13 | 000 | — | rs1 + sign-extended imm12의 하위 32비트 |
| `andi rd, rs1, imm` | I | 0x13 | 111 | — | rs1과 sign-extended imm12의 비트별 AND |
| `ori rd, rs1, imm` | I | 0x13 | 110 | — | rs1과 sign-extended imm12의 비트별 OR |
| `slti rd, rs1, imm` | I | 0x13 | 010 | — | signed(rs1) < sign-extended imm12이면 1, 그 외 0 |
| `lw rd, imm(rs1)` | I | 0x03 | 010 | — | rs1 + sign-extended imm12에서 32비트 word 읽기 |
| `sw rs2, imm(rs1)` | S | 0x23 | 010 | — | rs1 + sign-extended imm12에 rs2 32비트 기록 |
| `beq rs1, rs2, target` | B | 0x63 | 000 | — | 두 값이 같으면 PC+signed byte offset, 그 외 PC+4 |
| `jal rd, target` | J | 0x6F | — | — | rd←PC+4, PC←PC+signed byte offset |

명령 길이는 32비트이고 `x0`는 항상 0입니다. 수업 시험의 load/store 주소는 워드 정렬입니다.
B/J offset은 재조립한 byte offset이며 하위 1비트는 0입니다. R형 외 [31:25]에는 immediate 등이 있어 독립 funct7 필드가 없습니다.

[Harris 공개 HDL](https://pages.hmc.edu/harris/class/e85/old/fall24/RISCVsingle.sv.txt) · [Harris Appendix B](https://pages.hmc.edu/harris/ddca/ddcarv/DDCArv_AppB_Harris.pdf) · [RISC-V 공식 인코딩 목록](https://docs.riscv.org/reference/isa/unpriv/rv-32-64g.html)
