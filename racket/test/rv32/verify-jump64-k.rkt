#lang racket

(require "../../rv32/spec.rkt")
(require serval/lib/unittest)

(define tests
  (test-suite+
    "riscv32-jump64-k tests"
    (jit-verify-case '(BPF_JMP BPF_JA BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JEQ BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JGT BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JLT BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JGE BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JLE BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JNE BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JSGT BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JSLT BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JSGE BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JSLE BPF_K))
    (jit-verify-case '(BPF_JMP BPF_JSET BPF_K))
))

(module+ test
  (time (run-tests tests)))