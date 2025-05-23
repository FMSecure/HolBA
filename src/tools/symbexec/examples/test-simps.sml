open HolKernel Parse boolLib bossLib;


open birs_simpLib;
open birs_simp_instancesLib;

val default_exp_simp = birs_simp_default_core_exp_simp;
val armcm0_simp = birs_simp_default_armcm0_gen false birs_simpLib.birs_simp_ID_fun [];
val riscv_simp = birs_simp_default_riscv_gen false birs_simpLib.birs_simp_ID_fun [];
val riscv_storestore_simp = birs_simp_default_riscv_gen true birs_simpLib.birs_simp_ID_fun [];

val load_cheat_thm = prove(``
   !pcond.
   birs_simplification
      pcond
      (BExp_Load
         (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
         (BExp_Const (Imm32 0x10000DA0w))
         BEnd_LittleEndian
         Bit32)
      (BExp_Const (Imm32 0x10000DA8w))
``,
  cheat
);
val armcm0_ldcheat_simp = birs_simp_default_armcm0_gen false birs_simpLib.birs_simp_ID_fun [load_cheat_thm];


  val _ = birs_simp_instancesLib.simp_thms_tuple_subexp_extra :=
    [bir_symb_simpTheory.birs_simplification_Store_mem_thm,
    bir_symb_simpTheory.birs_simplification_Store_val_thm,
    bir_symb_simpTheory.birs_simplification_Store_addr_thm];
  val birs_simp_default_core_exp_store_plus_cm0_simp =
    let
      val include_64 = true;
      val include_32 = true;
      val mem_64 = false;
      val mem_32 = true;
      val riscv = false;
      val cm0 = true;
    in
      birs_simp_instancesLib.birs_simp_gen
        birs_simpLib.birs_simp_ID_fun
        []
        (birs_simp_instancesLib.simp_thms_tuple include_64 include_32 mem_64 mem_32 riscv cm0 [])
        (birs_simp_instancesLib.load_thms_tuple mem_64 mem_32)
        NONE
    end;
  (*val armcm0_simp=birs_simp_default_core_exp_store_plus_cm0_simp;*)

  val _ = birs_simp_regular_recurse_mode := false;
  val _ = birs_simp_regular_recurse_depth := 10;

val bexp_stores = ``       (BExp_Store
                              (BExp_Store
                                 (BExp_Store
                                    (BExp_Store
                                       (BExp_Store
                                          (BExp_Store
                                             (BExp_Den
                                                (BVar "sy_MEM8"
                                                   (BType_Mem Bit64 Bit8)))
                                             (BExp_BinExp BIExp_Plus
                                                (BExp_BinExp BIExp_Minus
                                                   (BExp_Den
                                                      (BVar "sy_x2"
                                                         (BType_Imm Bit64)))
                                                   (BExp_Const (Imm64 32w)))
                                                (BExp_Const (Imm64 24w)))
                                             BEnd_LittleEndian
                                             (BExp_Den
                                                (BVar "sy_x1"
                                                   (BType_Imm Bit64))))
                                          (BExp_BinExp BIExp_Plus
                                             (BExp_BinExp BIExp_Minus
                                                (BExp_Den
                                                   (BVar "sy_x2"
                                                      (BType_Imm Bit64)))
                                                (BExp_Const (Imm64 32w)))
                                             (BExp_Const (Imm64 16w)))
                                          BEnd_LittleEndian
                                          (BExp_Den
                                             (BVar "sy_x8"
                                                (BType_Imm Bit64))))
                                       (BExp_BinExp BIExp_Minus
                                          (BExp_BinExp BIExp_Minus
                                             (BExp_Den
                                                (BVar "sy_x2"
                                                   (BType_Imm Bit64)))
                                             (BExp_Const (Imm64 0w)))
                                          (BExp_Const (Imm64 20w)))
                                       BEnd_LittleEndian
                                       (BExp_Cast BIExp_LowCast
                                          (BExp_Const (Imm64 1w)) Bit32))
                                    (BExp_BinExp BIExp_Plus
                                       (BExp_BinExp BIExp_Minus
                                          (BExp_Den
                                             (BVar "sy_x2"
                                                (BType_Imm Bit64)))
                                          (BExp_Const (Imm64 64w)))
                                       (BExp_Const (Imm64 24w)))
                                    BEnd_LittleEndian
                                    (BExp_BinExp BIExp_Minus
                                       (BExp_Den
                                          (BVar "sy_x2" (BType_Imm Bit64)))
                                       (BExp_Const (Imm64 0w))))
                                 (BExp_BinExp BIExp_Minus
                                    (BExp_BinExp BIExp_Minus
                                       (BExp_Den
                                          (BVar "sy_x2" (BType_Imm Bit64)))
                                       (BExp_Const (Imm64 32w)))
                                    (BExp_Const (Imm64 24w)))
                                 BEnd_LittleEndian (BExp_Const (Imm64 3w)))
                              (BExp_BinExp BIExp_Minus
                                 (BExp_BinExp BIExp_Minus
                                    (BExp_Den
                                       (BVar "sy_x2" (BType_Imm Bit64)))
                                    (BExp_Const (Imm64 32w)))
                                 (BExp_Const (Imm64 28w)))
                              BEnd_LittleEndian
                              (BExp_Cast BIExp_LowCast
                                 (BExp_Const (Imm64 7w)) Bit32))
``;

val test_cases = [
  (default_exp_simp,
  ``BExp_BinExp BIExp_And
            (BExp_BinExp BIExp_And
               (BExp_BinExp BIExp_And
                  (BExp_UnaryExp BIExp_Not
                     (BExp_Den (BVar "sy_ModeHandler" (BType_Imm Bit1))))
                  (BExp_BinExp BIExp_And
                     (BExp_BinPred BIExp_Equal
                        (BExp_BinExp BIExp_And
                           (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
                           (BExp_Const (Imm32 3w))) (BExp_Const (Imm32 0w)))
                     (BExp_BinExp BIExp_And
                        (BExp_BinExp BIExp_And
                           (BExp_BinPred BIExp_LessThan
                              (BExp_Const (Imm32 0x10001FE0w))
                              (BExp_Den
                                 (BVar "sy_SP_process" (BType_Imm Bit32))))
                           (BExp_BinPred BIExp_LessOrEqual
                              (BExp_Den
                                 (BVar "sy_SP_process" (BType_Imm Bit32)))
                              (BExp_Const (Imm32 0x10001FF0w))))
                        (BExp_BinPred BIExp_LessOrEqual
                           (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
                           (BExp_Const (Imm64 0xFFFFF38w))))))
               (BExp_Den (BVar "syp_gen" (BType_Imm Bit1))))
            (BExp_UnaryExp BIExp_Not
               (BExp_BinPred BIExp_LessOrEqual
                  (BExp_BinExp BIExp_LeftShift (BExp_Const (Imm32 1w))
                     (BExp_Const (Imm32 16w)))
                  (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))))``,
  ``BExp_IfThenElse
                (BExp_BinPred BIExp_LessOrEqual
                   (BExp_BinExp BIExp_LeftShift (BExp_Const (Imm32 1w))
                      (BExp_Const (Imm32 16w)))
                   (BExp_Den (BVar "sy_R0" (BType_Imm Bit32))))
                (BExp_BinExp BIExp_Plus
                   (BExp_BinExp BIExp_Plus
                      (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
                      (BExp_Const (Imm64 4w))) (BExp_Const (Imm64 1w)))
                (BExp_BinExp BIExp_Plus
                   (BExp_BinExp BIExp_Plus
                      (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
                      (BExp_Const (Imm64 4w))) (BExp_Const (Imm64 3w)))``,
  ``(BExp_BinExp BIExp_Plus (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
       (BExp_Const (Imm64 (7w))))``),

  (riscv_simp,
  ``(BExp_Const (Imm1 1w))``,
  ``BExp_Cast BIExp_SignedCast
                        (BExp_Cast BIExp_LowCast
                           (BExp_Cast BIExp_SignedCast
                              (BExp_Cast BIExp_LowCast
                                 (BExp_BinExp BIExp_Plus
                                    (BExp_Cast BIExp_SignedCast
                                       (BExp_Cast BIExp_LowCast
                                          (BExp_Const (Imm64 3w)) Bit32)
                                       Bit64)
                                    (BExp_Cast BIExp_SignedCast
                                       (BExp_Cast BIExp_LowCast
                                          (BExp_Const (Imm64 7w)) Bit32)
                                       Bit64)) Bit32) Bit64) Bit32) Bit64``,
  ``BExp_Const (Imm64 (10w))``),

  (riscv_simp,
  ``(BExp_Const (Imm1 1w))``,
  ``BExp_Cast BIExp_SignedCast
                        (BExp_Cast BIExp_LowCast
                           (BExp_Cast BIExp_SignedCast
                              (BExp_Cast BIExp_LowCast
                                 (BExp_BinExp BIExp_Plus
                                    (BExp_Cast BIExp_SignedCast
                                       (BExp_Cast BIExp_LowCast
                                          (BExp_Const (Imm64 3w)) Bit32)
                                       Bit64)
                                    (BExp_Cast BIExp_SignedCast
                                       (BExp_Cast
                                                         BIExp_LowCast
                                                         (BExp_Const
                                                            (Imm64 1w))
                                                         Bit32) Bit64))
                                 Bit32) Bit64) Bit32) Bit64``,
  ``BExp_Const (Imm64 (4w))``),

  (riscv_simp,
  ``BExp_BinExp BIExp_And
                    (BExp_BinPred BIExp_Equal
                       (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                       (BExp_Const (Imm64 pre_x2)))
                    (BExp_BinExp BIExp_And
                       (BExp_BinPred BIExp_Equal
                          (BExp_BinExp BIExp_And
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 7w)))
                          (BExp_Const (Imm64 0w)))
                       (BExp_BinExp BIExp_And
                          (BExp_BinPred BIExp_LessOrEqual
                             (BExp_Const (Imm64 4096w))
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64))))
                          (BExp_BinPred BIExp_LessThan
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 0x100000000w)))))``,
  ``(BExp_Load
                           (BExp_Store
                              (BExp_Den (BVar "sy_MEM8" (BType_Mem Bit64 Bit8)))
                              (BExp_BinExp BIExp_Minus
                                 (BExp_BinExp BIExp_Minus
                                    (BExp_Den
                                       (BVar "sy_x2" (BType_Imm Bit64)))
                                    (BExp_Const (Imm64 32w)))
                                 (BExp_Const (Imm64 28w)))
                              BEnd_LittleEndian
                              (BExp_Cast BIExp_LowCast
                                 (BExp_Const (Imm64 7w)) Bit32))
                           (BExp_BinExp BIExp_Minus
                              (BExp_BinExp BIExp_Minus
                                 (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                                 (BExp_Const (Imm64 32w)))
                              (BExp_Const (Imm64 28w))) BEnd_LittleEndian
                           Bit32)``,
  ``BExp_Cast BIExp_LowCast (BExp_Const (Imm64 7w)) Bit32``),

  (riscv_simp,
  ``BExp_BinExp BIExp_And
                    (BExp_BinPred BIExp_Equal
                       (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                       (BExp_Const (Imm64 pre_x2)))
                    (BExp_BinExp BIExp_And
                       (BExp_BinPred BIExp_Equal
                          (BExp_BinExp BIExp_And
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 7w)))
                          (BExp_Const (Imm64 0w)))
                       (BExp_BinExp BIExp_And
                          (BExp_BinPred BIExp_LessOrEqual
                             (BExp_Const (Imm64 4096w))
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64))))
                          (BExp_BinPred BIExp_LessThan
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 0x100000000w)))))``,
  ``(BExp_Load
                           ^bexp_stores
                           (BExp_BinExp BIExp_Minus
                              (BExp_BinExp BIExp_Minus
                                 (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                                 (BExp_Const (Imm64 32w)))
                              (BExp_Const (Imm64 28w))) BEnd_LittleEndian
                           Bit32)``,
  ``BExp_Cast BIExp_LowCast (BExp_Const (Imm64 7w)) Bit32``),

  (riscv_simp,
  ``BExp_BinExp BIExp_And
                    (BExp_BinPred BIExp_Equal
                       (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                       (BExp_Const (Imm64 pre_x2)))
                    (BExp_BinExp BIExp_And
                       (BExp_BinPred BIExp_Equal
                          (BExp_BinExp BIExp_And
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 7w)))
                          (BExp_Const (Imm64 0w)))
                       (BExp_BinExp BIExp_And
                          (BExp_BinPred BIExp_LessOrEqual
                             (BExp_Const (Imm64 4096w))
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64))))
                          (BExp_BinPred BIExp_LessThan
                             (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                             (BExp_Const (Imm64 0x100000000w)))))``,
  ``BExp_Cast BIExp_SignedCast
                        (BExp_Load
                           (BExp_Store
                              (BExp_Store
                                 (BExp_Store
                                    (BExp_Store
                                       (BExp_Store
                                          (BExp_Store
                                             (BExp_Den
                                                (BVar "sy_MEM8"
                                                   (BType_Mem Bit64 Bit8)))
                                             (BExp_BinExp BIExp_Plus
                                                (BExp_BinExp BIExp_Minus
                                                   (BExp_Den
                                                      (BVar "sy_x2"
                                                         (BType_Imm Bit64)))
                                                   (BExp_Const (Imm64 32w)))
                                                (BExp_Const (Imm64 24w)))
                                             BEnd_LittleEndian
                                             (BExp_Den
                                                (BVar "sy_x1"
                                                   (BType_Imm Bit64))))
                                          (BExp_BinExp BIExp_Plus
                                             (BExp_BinExp BIExp_Minus
                                                (BExp_Den
                                                   (BVar "sy_x2"
                                                      (BType_Imm Bit64)))
                                                (BExp_Const (Imm64 32w)))
                                             (BExp_Const (Imm64 16w)))
                                          BEnd_LittleEndian
                                          (BExp_Den
                                             (BVar "sy_x8"
                                                (BType_Imm Bit64))))
                                       (BExp_BinExp BIExp_Minus
                                          (BExp_BinExp BIExp_Minus
                                             (BExp_Den
                                                (BVar "sy_x2"
                                                   (BType_Imm Bit64)))
                                             (BExp_Const (Imm64 0w)))
                                          (BExp_Const (Imm64 20w)))
                                       BEnd_LittleEndian
                                       (BExp_Cast BIExp_LowCast
                                          (BExp_Const (Imm64 1w)) Bit32))
                                    (BExp_BinExp BIExp_Plus
                                       (BExp_BinExp BIExp_Minus
                                          (BExp_Den
                                             (BVar "sy_x2"
                                                (BType_Imm Bit64)))
                                          (BExp_Const (Imm64 64w)))
                                       (BExp_Const (Imm64 24w)))
                                    BEnd_LittleEndian
                                    (BExp_BinExp BIExp_Minus
                                       (BExp_Den
                                          (BVar "sy_x2" (BType_Imm Bit64)))
                                       (BExp_Const (Imm64 0w))))
                                 (BExp_BinExp BIExp_Minus
                                    (BExp_BinExp BIExp_Minus
                                       (BExp_Den
                                          (BVar "sy_x2" (BType_Imm Bit64)))
                                       (BExp_Const (Imm64 32w)))
                                    (BExp_Const (Imm64 24w)))
                                 BEnd_LittleEndian (BExp_Const (Imm64 3w)))
                              (BExp_BinExp BIExp_Minus
                                 (BExp_BinExp BIExp_Minus
                                    (BExp_Den
                                       (BVar "sy_x2" (BType_Imm Bit64)))
                                    (BExp_Const (Imm64 32w)))
                                 (BExp_Const (Imm64 28w)))
                              BEnd_LittleEndian
                              (BExp_Cast BIExp_LowCast
                                 (BExp_Const (Imm64 7w)) Bit32))
                           (BExp_BinExp BIExp_Minus
                              (BExp_BinExp BIExp_Minus
                                 (BExp_Den (BVar "sy_x2" (BType_Imm Bit64)))
                                 (BExp_Const (Imm64 32w)))
                              (BExp_Const (Imm64 28w))) BEnd_LittleEndian
                           Bit32) Bit64``,
  ``BExp_Const (Imm64 7w)(*BExp_Cast BIExp_SignedCast
       (BExp_Cast BIExp_LowCast (BExp_Const (Imm64 7w)) Bit32) Bit64*)``),

  (armcm0_simp,
  ``(BExp_BinPred BIExp_Equal
      (BExp_Cast BIExp_UnsignedCast
        (BExp_Cast BIExp_LowCast
          (BExp_BinExp BIExp_RightShift
            (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
            (BExp_Const (Imm32 31w))) Bit8) Bit32)
      (BExp_Const (Imm32 0w)))``,
  ``BExp_IfThenElse
    (BExp_BinPred BIExp_Equal
      (BExp_Cast BIExp_UnsignedCast
        (BExp_Cast BIExp_LowCast
          (BExp_BinExp BIExp_RightShift
            (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
            (BExp_Const (Imm32 31w))) Bit8) Bit32)
      (BExp_Const (Imm32 0w)))
    (BExp_BinExp BIExp_Plus
                      (BExp_BinExp BIExp_Plus
                         (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
                         (BExp_Const (Imm64 19w))) (BExp_Const (Imm64 3w)))
    (BExp_BinExp BIExp_Plus
                      (BExp_BinExp BIExp_Plus
                         (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
                         (BExp_Const (Imm64 19w))) (BExp_Const (Imm64 1w)))``,
  ``BExp_BinExp BIExp_Plus (BExp_Den (BVar "sy_countw" (BType_Imm Bit64)))
       (BExp_Const (Imm64 (22w)))``),

  (default_exp_simp,
  ``(BExp_Const (Imm1 1w))``,
  ``
  BExp_BinExp BIExp_Plus
    (BExp_BinExp BIExp_Plus
      (BExp_Den (BVar "abcd" (BType_Imm Bit64)))
        (BExp_Const (Imm64 22w)))
    (BExp_Const (Imm64 14w))``,
  ``BExp_BinExp BIExp_Plus (BExp_Den (BVar "abcd" (BType_Imm Bit64)))
       (BExp_Const (Imm64 (36w)))``),

  (default_exp_simp,
  ``
  BExp_BinPred BIExp_Equal
    (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
    (BExp_Const (Imm32 35w))``,
  ``
  BExp_IfThenElse
    (BExp_BinPred BIExp_LessThan
      (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
      (BExp_Const (Imm32 31w)))
    (BExp_Const (Imm64 19w))
    (BExp_Const (Imm64 77w))``,
  ``BExp_Const (Imm64 77w)``),

  (default_exp_simp,
  ``
  BExp_BinPred BIExp_Equal
    (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
    (BExp_Const (Imm32 35w))
  ``,
  ``
  BExp_BinExp BIExp_Minus
    (BExp_IfThenElse
      (BExp_BinPred BIExp_LessThan
         (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
         (BExp_Const (Imm32 31w)))
      (BExp_Const (Imm64 19w))
      (BExp_Const (Imm64 77w)))
    (BExp_Const (Imm64 2w))``,
  ``BExp_Const (Imm64 75w)``),

  (armcm0_ldcheat_simp,
  ``
  (BExp_Const (Imm1 1w))
  ``,
  ``
  BExp_Load
      (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
      (BExp_Const (Imm32 0x10000DA0w))
      BEnd_LittleEndian
      Bit32``,
  ``BExp_Const (Imm32 0x10000DA8w)``),

  (armcm0_simp,
  ``
  (BExp_Const (Imm1 1w))
  ``,
  ``
  (BExp_BinExp BIExp_Minus
      (BExp_Const (Imm32 5w))
      (BExp_Const (Imm32 1w)))``,
  ``BExp_Const (Imm32 4w)``),

  (armcm0_simp,
  ``
  (BExp_Const (Imm1 1w))
  ``,
  ``
  (BExp_BinExp BIExp_Minus
      (BExp_BinExp BIExp_Minus
         (BExp_Den (BVar "R1" (BType_Imm Bit32)))
         (BExp_Const (Imm32 1w)))
      (BExp_Const (Imm32 1w)))``,
  ``BExp_BinExp BIExp_Minus
         (BExp_Den (BVar "R1" (BType_Imm Bit32)))
         (BExp_Const (Imm32 2w))``),

  (armcm0_simp,
  ``BExp_BinExp BIExp_And
      (BExp_BinPred BIExp_Equal
         (BExp_BinExp BIExp_And
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 3w)))
         (BExp_Const (Imm32 0w)))
      (BExp_BinExp BIExp_And
         (BExp_BinPred BIExp_LessThan
            (BExp_Const (Imm32 0x10001FE4w))
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32))))
         (BExp_BinPred BIExp_LessOrEqual
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 0x10001FF0w))))``,
  ``
      (BExp_Load
         (BExp_Store
            (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
            (BExp_BinExp BIExp_Minus
               (BExp_Den
                  (BVar "sy_SP_process" (BType_Imm Bit32)))
               (BExp_Const (Imm32 41w))) BEnd_LittleEndian
            (BExp_Cast BIExp_LowCast
               (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
               Bit8))
         (BExp_Const (Imm32 0x10001ED4w))
         BEnd_LittleEndian
         Bit16)``,
  ``
      (BExp_Load
         (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
         (BExp_Const (Imm32 0x10001ED4w))
         BEnd_LittleEndian
         Bit16)``),

  (armcm0_simp,
  ``BExp_BinExp BIExp_And
      (BExp_BinPred BIExp_Equal
         (BExp_BinExp BIExp_And
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 3w)))
         (BExp_Const (Imm32 0w)))
      (BExp_BinExp BIExp_And
         (BExp_BinPred BIExp_LessThan
            (BExp_Const (Imm32 0x10001FE4w))
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32))))
         (BExp_BinPred BIExp_LessOrEqual
            (BExp_Den
               (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 0x10001FF0w))))``,
  ``BExp_Cast BIExp_UnsignedCast
      (BExp_Load
         (BExp_Store
            (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
            (BExp_BinExp BIExp_Minus
               (BExp_Den
                  (BVar "sy_SP_process" (BType_Imm Bit32)))
               (BExp_Const (Imm32 41w))) BEnd_LittleEndian
            (BExp_Cast BIExp_LowCast
               (BExp_Den (BVar "sy_R0" (BType_Imm Bit32)))
               Bit8))
         (BExp_Const (Imm32 0x10001ED4w))
         BEnd_LittleEndian
         Bit16)
      Bit32``,
  ``BExp_Cast BIExp_UnsignedCast
      (BExp_Load
         (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
         (BExp_Const (Imm32 0x10001ED4w))
         BEnd_LittleEndian
         Bit16)
      Bit32``),

  (armcm0_simp,
  ``(BExp_Const (Imm1 1w))``,
  ``(BExp_BinExp BIExp_Plus
              ((BExp_BinExp BIExp_Minus
                (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
                (BExp_Const (Imm32 104w))))
              (BExp_Const (Imm32 12w)))``,
  ``(BExp_BinExp BIExp_Minus
       (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
       (BExp_Const (Imm32 92w)))``),

  (birs_simp_default_core_exp_store_plus_cm0_simp,
  ``BExp_BinExp BIExp_And
      (BExp_BinPred BIExp_Equal
        (BExp_BinExp BIExp_And
          (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
          (BExp_Const (Imm32 2w))) (BExp_Const (Imm32 0w)))
      (BExp_BinExp BIExp_And
          (BExp_BinPred BIExp_LessThan
            (BExp_Const (Imm32 0x10001FE0w))
            (BExp_Den
                (BVar "sy_SP_process" (BType_Imm Bit32))))
          (BExp_BinPred BIExp_LessOrEqual
            (BExp_Den
                (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 0x10001FF0w))))``,
  ``BExp_BinExp BIExp_Plus
      (BExp_Load
        (BExp_Store
          (BExp_Store
            (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
            (BExp_BinExp BIExp_Minus
              (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
              (BExp_Const (Imm32 92w)))
            BEnd_LittleEndian
            (BExp_Const (Imm32 5w)))
          (BExp_BinExp BIExp_Minus
            (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 52w)))
          BEnd_LittleEndian
          (BExp_Const (Imm32 7w)))
        (BExp_BinExp BIExp_Minus
          (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
          (BExp_Const (Imm32 52w)))
        BEnd_LittleEndian Bit32)
      (BExp_Const (Imm32 16w))``,
  ``(BExp_Const (Imm32 23w))``),

  (birs_simp_default_core_exp_store_plus_cm0_simp,
  ``BExp_BinExp BIExp_And
      (BExp_BinPred BIExp_Equal
        (BExp_BinExp BIExp_And
          (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
          (BExp_Const (Imm32 2w))) (BExp_Const (Imm32 0w)))
      (BExp_BinExp BIExp_And
          (BExp_BinPred BIExp_LessThan
            (BExp_Const (Imm32 0x10001FE0w))
            (BExp_Den
                (BVar "sy_SP_process" (BType_Imm Bit32))))
          (BExp_BinPred BIExp_LessOrEqual
            (BExp_Den
                (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 0x10001FF0w))))``,
  ``BExp_BinExp BIExp_Plus
      (BExp_Load
        (BExp_Store
          (BExp_Store
            (BExp_Den (BVar "sy_MEM" (BType_Mem Bit32 Bit8)))
            (BExp_BinExp BIExp_Minus
              (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
              (BExp_Const (Imm32 92w)))
            BEnd_LittleEndian
            (BExp_Const (Imm32 5w)))
          (BExp_BinExp BIExp_Minus
            (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
            (BExp_Const (Imm32 52w)))
          BEnd_LittleEndian
          (BExp_Const (Imm32 7w)))
        (BExp_BinExp BIExp_Minus
          (BExp_Den (BVar "sy_SP_process" (BType_Imm Bit32)))
          (BExp_Const (Imm32 92w)))
        BEnd_LittleEndian Bit32)
      (BExp_Const (Imm32 16w))``,
  ``(BExp_Const (Imm32 21w))``)
];


  val skip_num_tests = 0;

(*
val (simp_fun, pcond, bexp, expected) = hd test_cases;
*)

val idx_r = ref skip_num_tests;
fun test (simp_fun, pcond, bexp, expected) =
  let
    val _ = print ("\n\n\ntest "^Int.toString (!idx_r)^" starts:\n");
    val _ = idx_r := (!idx_r) + 1;

    (* TODO: better first check that pcond is sat *)
    val simp_tm = birs_simp_gen_term pcond bexp;
    (*val _ = print_term simp_tm;*)
    val res_thm = birs_simpLib.simp_try_apply_gen simp_fun simp_tm;
    (*val _ = print_thm res_thm;*)
    val expected_thm_concl = subst [``symbexp':bir_exp_t`` |-> expected] simp_tm;
    val is_expected = identical expected_thm_concl (concl res_thm);

    val _ = if is_expected then print "success\n" else (
        print "\nexpected:\n";
        print_term expected_thm_concl;
        print "\nwe have\n";
        print_thm res_thm;
        raise Fail "not as expected"
    );
  in () end;

val _ = List.app test (List.drop(test_cases, !idx_r));
