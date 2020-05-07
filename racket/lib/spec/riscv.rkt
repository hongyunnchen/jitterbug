#lang rosette

(require "../hybrid-memory.rkt"
         "../bpf-common.rkt"
         "../riscv-common.rkt"
         "bpf.rkt"
         (prefix-in bpf: serval/bpf)
         (prefix-in riscv: serval/riscv/interp)
         (prefix-in core: serval/lib/core))

(provide (all-defined-out))

(define (code-size vec)
  (* 4 (vector-length vec)))

(define (bpf-to-target-pc ctx target-pc-base bpf-pc)
  (define offsets (context-offset ctx))
  (define (prev-offset insn)
    (if (bveq insn (bv 0 32)) (bv 0 32) (offsets (bvsub insn (bv 1 32)))))
  (define ty (type-of target-pc-base))
  (bvadd
    target-pc-base
    (bvmul (zero-extend (prev-offset bpf-pc) ty) (bv 4 ty))))

(define (riscv-init-ctx insns-addr insn-idx program-length aux)
  (define-symbolic* offsets (~> (bitvector 32) (bitvector 32)))
  (define-symbolic* seen (~> (bitvector 5) boolean?))

  (define ninsns
    (if (equal? (bv 0 32) insn-idx)
        (bv 0 32)
        (offsets (bvsub insn-idx (bv 1 32)))))

  ; The epilogue is at the end of the program.
  (define epilogue-offset (offsets (bvsub1 program-length)))

  ; Some stack size
  (define-symbolic* stack_size (bitvector 32))

  ; Dummy saved regs
  (define saved-regs #f)

  (define ctx (context program-length (vector) insns-addr ninsns epilogue-offset stack_size offsets
                       seen saved-regs aux))
  ctx)

(define (run-jitted-code base riscv-cpu insns)
  (for/all ([insns insns #:exhaustive])
    (interpret-program base riscv-cpu insns)))

(define (interpret-program base cpu insns)
  ; cpu -> riscv cpu
  ; intrs -> vector of instructions
  (for/all ([pc (riscv:cpu-pc cpu) #:exhaustive])
    (begin
      (riscv:set-cpu-pc! cpu pc)
      (define insn (fetch insns base pc))
      (when insn
        (riscv:interpret-insn cpu insn)
        (interpret-program base cpu insns)))))

(define (fetch instrs base pc)
  (define n (bitvector->natural (bvudiv (bvsub pc base) (bv 4 (type-of pc)))))
  (cond
    [(term? n) #f]
    [(< n (vector-length instrs)) (vector-ref instrs n)]
    [else #f]))

(define ((riscv-init-cpu xlen) ctx riscv-pc memmgr)
  (define riscv-cpu (riscv:init-cpu null null (lambda a memmgr) #:xlen xlen))
  (riscv:set-cpu-pc! riscv-cpu riscv-pc)
  riscv-cpu)

(define ((riscv-abstract-regs rv_get_bpf_reg) rv_cpu)
  (apply bpf:regs
    (for/list ([i (in-range MAX_BPF_JIT_REG)])
      (rv_get_bpf_reg rv_cpu (bpf:idx->reg i)))))