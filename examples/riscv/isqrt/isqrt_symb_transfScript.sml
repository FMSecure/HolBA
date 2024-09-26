open HolKernel boolLib Parse bossLib;

open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;

open bir_symbLib;

open isqrtTheory;
open isqrt_specTheory;
open isqrt_symb_execTheory;

val _ = new_theory "isqrt_symb_transf";

(* ------------------------------- *)
(* BIR symbolic execution analysis *)
(* ------------------------------- *)

(* before loop contract *)

val init_addr_1_tm = (snd o dest_eq o concl) isqrt_init_addr_1_def;
val end_addr_1_tm = (snd o dest_eq o concl) isqrt_end_addr_1_def;

val bspec_pre_1_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_pre_1_def;
val bspec_post_1_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_post_1_def;

val bspec_cont_1_thm =
 bir_symb_transfer init_addr_1_tm end_addr_1_tm bspec_pre_1_tm bspec_post_1_tm
  bir_isqrt_prog_def isqrt_birenvtyl_def
  bspec_isqrt_pre_1_def bspec_isqrt_post_1_def isqrt_prog_vars_list_def
  isqrt_symb_analysis_1_thm isqrt_bsysprecond_1_thm isqrt_prog_vars_thm;

Theorem bspec_cont_isqrt_1:
 bir_cont bir_isqrt_prog bir_exp_true
  (BL_Address (Imm64 ^init_addr_1_tm)) {BL_Address (Imm64 ^end_addr_1_tm)} {}
  ^bspec_pre_1_tm
  (\l. if l = BL_Address (Imm64 ^end_addr_1_tm)
       then ^bspec_post_1_tm
       else bir_exp_false)
Proof
 rw [bir_isqrt_prog_def,bspec_cont_1_thm]
QED

(* loop body contract *)

val init_addr_2_tm = (snd o dest_eq o concl) isqrt_init_addr_2_def;
val end_addr_2_tm = (snd o dest_eq o concl) isqrt_end_addr_2_def;

val bspec_pre_2_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_pre_2_def;
val bspec_post_2_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_post_2_def;

val bspec_cont_2_thm =
 bir_symb_transfer init_addr_2_tm end_addr_2_tm bspec_pre_2_tm bspec_post_2_tm
  bir_isqrt_prog_def isqrt_birenvtyl_def
  bspec_isqrt_pre_2_def bspec_isqrt_post_2_def isqrt_prog_vars_list_def
  isqrt_symb_analysis_2_thm isqrt_bsysprecond_2_thm isqrt_prog_vars_thm;

Theorem bspec_cont_isqrt_2:
 bir_cont bir_isqrt_prog bir_exp_true
  (BL_Address (Imm64 ^init_addr_2_tm)) {BL_Address (Imm64 ^end_addr_2_tm)} {}
  ^bspec_pre_2_tm
  (\l. if l = BL_Address (Imm64 ^end_addr_2_tm)
       then ^bspec_post_2_tm
       else bir_exp_false)
Proof
 rw [bir_isqrt_prog_def,bspec_cont_2_thm]
QED

(* branch contract *)

val init_addr_tm = (snd o dest_eq o concl) isqrt_init_addr_3_def;
val end_addr_1_tm = (snd o dest_eq o concl) isqrt_end_addr_3_loop_def;
val end_addr_2_tm = (snd o dest_eq o concl) isqrt_end_addr_3_ret_def;

val bspec_pre_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_pre_3_def;
val bspec_post_1_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_post_3_loop_def;
val bspec_post_2_tm = (lhs o snd o strip_forall o concl) bspec_isqrt_post_3_ret_def;

val bspec_cont_3_thm =
 bir_symb_transfer_two init_addr_tm end_addr_1_tm end_addr_2_tm
 bspec_pre_tm bspec_post_1_tm bspec_post_2_tm
 bir_isqrt_prog_def isqrt_birenvtyl_def
 bspec_isqrt_pre_3_def bspec_isqrt_post_3_loop_def bspec_isqrt_post_3_ret_def isqrt_prog_vars_list_def
 isqrt_symb_analysis_3_thm isqrt_bsysprecond_3_thm isqrt_prog_vars_thm;

Theorem bspec_cont_isqrt_3:
 bir_cont bir_isqrt_prog bir_exp_true
  (BL_Address (Imm64 ^init_addr_tm))
  {BL_Address (Imm64 ^end_addr_1_tm); BL_Address (Imm64 ^end_addr_2_tm)} {}
  ^bspec_pre_tm
  (\l. if l = BL_Address (Imm64 ^end_addr_1_tm) then ^bspec_post_1_tm
       else if l = BL_Address (Imm64 ^end_addr_2_tm) then ^bspec_post_2_tm
       else bir_exp_false)
Proof
 rw [bir_isqrt_prog_def,bspec_cont_3_thm]
QED

val _ = export_theory ();
