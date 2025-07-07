meta:
  id: amd_ucode
  title: AMD Microcode Patch File
  file-extension: bin
  xref:
    wiki: https://github.com/google/security-research/blob/master/pocs/cpus/entrysign/zentool/docs/intro.md
  license: Apache-2.0
  endian: le

doc: |
  A format for manipulating microcode patches for AMD Zen processors, as reverse-engineered
  by the zentool project.

seq:
  - id: header
    type: ucode_header
    doc: The main header of the microcode patch.
  - id: match_regs
    type: match_t
    repeat: expr
    repeat-expr: header.n_match
    doc: An array of match registers used to redirect execution from ROM to Patch RAM.
  - id: instructions
    type: ucode_ops
    repeat: expr
    repeat-expr: header.n_quad
    doc: The sequence of micro-operations (quads) that form the patch.

enums:
  zen_opclass_t:
    0: spec
    1: br
    2: ld
    4: stn
    5: st
    6: regx
    7: reg
  zen_seg_t:
    0: vs
    5: ms
    6: ls
    9: ps
  zen_reg_opcode_t:
    25: nsub
    48: and_
    64: shl
    65: bll
    66: rol
    68: rlc
    70: rrd
    71: src
    72: shr
    74: ror
    76: rrc
    79: srd
    80: sub
    82: sbb
    85: nadd
    93: adc
    95: add
    92: add2
    94: add3
    112: popcnt
    114: sbit
    177: xor
    184: or_
    169: bswap
    160: mov
    147: mov2
    127: vzu_32b
    111: vzu_64b
  zen_ldst_opcode_t:
    0: ldst
  zen_spec_opcode_t:
    255: nop
  zen_br_opcode_t:
    5: jmp
  zen_reg_t:
    0: temp_r0
    1: temp_r1
    2: temp_r2
    3: temp_r3
    4: temp_r4
    5: temp_r5
    6: temp_r6
    7: temp_r7
    8: temp_r8
    9: temp_r9
    10: temp_r10
    11: temp_r11
    12: temp_r12
    13: temp_r13
    14: temp_r14
    15: temp_r15
    16: rax
    17: rcx
    18: rdx
    19: rbx
    20: rsp
    21: rbp
    22: rsi
    23: rdi
    24: r8
    25: r9
    26: r10
    27: r11
    28: r12
    29: r13
    30: r14
    31: r15

types:
  ucode_header:
    doc: Corresponds to the `ucodehdr` struct.
    seq:
      - id: date
        type: u4
      - id: revision
        type: u4
      - id: format
        type: u2
      - id: patch_len
        type: u1
      - id: init
        type: u1
      - id: checksum
        type: u4
      - id: nb_vid
        type: u2
      - id: nb_did
        type: u2
      - id: sb_vid
        type: u2
      - id: sb_did
        type: u2
      - id: cpuid
        type: u4
      - id: bios_rev
        type: u1
      - id: flags
        type: u1
      - id: reserved
        type: u1
      - id: reserved2
        type: u1
      - id: signature
        size: 256
      - id: modulus
        size: 256
      - id: check
        size: 256
      - id: options
        type: options_t
      - id: rev
        type: u4
    instances:
      n_match:
        doc: Number of match registers, determined by the patch format.
        value: 'format == 0x8004 ? 22 : (format == 0x8005 ? 38 : (format == 0x8015 ? 60 : (format == 0x8010 ? 60 : 0)))'
      n_quad:
        doc: Number of instruction quads, determined by the patch format.
        value: 'format == 0x8004 ? 64 : (format == 0x8005 ? 128 : (format == 0x8015 ? 370 : (format == 0x8010 ? 370 : 0)))'

  options_t:
    seq:
      - id: autorun
        type: u1
      - id: encrypted
        type: u1
      - id: unknown1
        type: u1
      - id: unknown2
        type: u1

  match_t:
    doc: Corresponds to the `match_t` union.
    seq:
      - id: value
        type: u4
    instances:
      m1:
        value: 'value & 0x1FFF'
      reg1_enabled:
        value: '(value >> 13) & 1'
      m2:
        value: '(value >> 14) & 0x1FFF'
      reg2_enabled:
        value: '(value >> 27) & 1'

  ucode_ops:
    doc: A single micro-operation, consisting of a quad and a sequence word.
    seq:
      - id: quad
        type: uop_quad
      - id: seq
        type: seq_word

  uop_quad:
    doc: A set of four micro-instructions that are executed together.
    seq:
      - id: instructions
        type: base_op
        repeat: expr
        repeat-expr: 4

  seq_word:
    doc: Controls the flow of execution, indicating the next quad to be executed.
    seq:
      - id: value
        type: u4

  base_op:
    doc: A generic 64-bit micro-operation. The `op_class` determines the actual instruction type.
    seq:
      - id: value
        type: u8
    instances:
      op_class:
        value: '(value >> 59) & 0x7'
        enum: zen_opclass_t
      op:
        type:
          switch-on: op_class
          cases:
            zen_opclass_t::spec: spec_op(value)
            zen_opclass_t::br: br_op(value)
            zen_opclass_t::ld: ldst_op(value)
            zen_opclass_t::stn: ldst_op(value)
            zen_opclass_t::st: ldst_op(value)
            zen_opclass_t::regx: reg_op(value)
            zen_opclass_t::reg: reg_op(value)

  reg_op:
    doc: A register-based operation.
    params:
      - id: value
        type: u8
    instances:
      imm16:
        value: 'value & 0xFFFF'
      isig:
        value: '(value >> 16) & 1'
      mode3:
        value: '(value >> 19) & 1'
      rmod:
        value: '(value >> 35) & 1'
      cc:
        value: '(value >> 36) & 0xF'
      ss:
        value: '(value >> 40) & 1'
      size:
        value: '(value >> 41) & 0x3'
      sizemsb:
        value: '(value >> 43) & 1'
      pada:
        value: '(value >> 44) & 0x3'
      type:
        value: '(value >> 46) & 0xFF'
        enum: zen_reg_opcode_t
      ext:
        value: '(value >> 54) & 0xF'
      reg0_idx:
        value: '(value >> 20) & 0x1F'
        enum: zen_reg_t
      reg1_idx:
        value: '(value >> 25) & 0x1F'
        enum: zen_reg_t
      reg2_idx:
        value: '(value >> 30) & 0x1F'
        enum: zen_reg_t

  ldst_op:
    doc: A load or store operation.
    params:
      - id: value
        type: u8
    instances:
      imm:
        value: 'value & 0x3FF'
      segment:
        value: '(value >> 10) & 0xF'
        enum: zen_seg_t
      unkn1:
        value: '(value >> 14) & 1'
      nop3:
        value: '(value >> 15) & 1'
      unkn2:
        value: '(value >> 16) & 1'
      mode:
        value: '(value >> 17) & 0x3'
      wordsz:
        value: '(value >> 19) & 1'
      unknf:
        value: '(value >> 20) & 1'
      rmod:
        value: '(value >> 36) & 1'
      op3:
        value: '(value >> 37) & 1'
      unkn6:
        value: '(value >> 38) & 0xF'
      size:
        value: '(value >> 42) & 0x3'
      width:
        value: '(value >> 44) & 1'
      ldst:
        value: '(value >> 45) & 1'
      unkn3:
        value: '(value >> 46) & 0x3F'
      unknx:
        value: '(value >> 52) & 0x7'
      type:
        value: '(value >> 55) & 0xF'
        enum: zen_ldst_opcode_t
      reg0_idx:
        value: '(value >> 21) & 0x1F'
        enum: zen_reg_t
      reg1_idx:
        value: '(value >> 26) & 0x1F'
        enum: zen_reg_t
      reg2_idx:
        value: '(value >> 31) & 0x1F'
        enum: zen_reg_t

  spec_op:
    doc: A special operation that is not issued to an execution unit.
    params:
      - id: value
        type: u8
    instances:
      imm16:
        value: 'value & 0xFFFF'
      isig:
        value: '(value >> 16) & 1'
      mode3:
        value: '(value >> 19) & 1'
      rmod:
        value: '(value >> 35) & 1'
      size:
        value: '(value >> 41) & 0x3'
      sizemsb:
        value: '(value >> 43) & 1'
      pada:
        value: '(value >> 44) & 0x3'
      type:
        value: '(value >> 46) & 0xFF'
        enum: zen_spec_opcode_t
      padc:
        value: '(value >> 54) & 0xF'
      reg0_idx:
        value: '(value >> 20) & 0x1F'
        enum: zen_reg_t
      reg1_idx:
        value: '(value >> 25) & 0x1F'
        enum: zen_reg_t
      reg2_idx:
        value: '(value >> 30) & 0x1F'
        enum: zen_reg_t

  br_op:
    doc: A branch operation.
    params:
      - id: value
        type: u8
    instances:
      imm16:
        value: 'value & 0xFFFF'
      isig:
        value: '(value >> 16) & 1'
      mode3:
        value: '(value >> 19) & 1'
      rmod:
        value: '(value >> 35) & 1'
      size:
        value: '(value >> 41) & 0x3'
      sizemsb:
        value: '(value >> 43) & 1'
      pada:
        value: '(value >> 44) & 0x3'
      type:
        value: '(value >> 46) & 0xFF'
        enum: zen_br_opcode_t
      padc:
        value: '(value >> 54) & 0xF'
      reg0_idx:
        value: '(value >> 20) & 0x1F'
        enum: zen_reg_t
      reg1_idx:
        value: '(value >> 25) & 0x1F'
        enum: zen_reg_t
      reg2_idx:
        value: '(value >> 30) & 0x1F'
        enum: zen_reg_t
