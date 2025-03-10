open HolKernel boolLib Parse bossLib;

open markerTheory;

open bir_bool_expSyntax;
open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;
open bir_exp_equivTheory;

open bir_riscv_backlifterTheory;
open bir_backlifterLib;
open bir_riscv_extrasTheory;
open bir_compositionLib;

open bir_lifting_machinesTheory;
open bir_typing_expTheory;
open bir_htTheory;

open bir_smtLib;

open bir_symbTheory birs_auxTheory;
open HolBACoreSimps;
open bir_program_transfTheory;

open total_program_logicTheory;
open total_ext_program_logicTheory;
open symb_prop_transferTheory;

open jgmt_rel_bir_contTheory;

open pred_setTheory;

open program_logicSimps;

open bir_env_oldTheory;
open bir_program_varsTheory;

open incr_spec_riscvTheory;

val _ = new_theory "incr_spec_bir";

(* --------------- *)
(* HL BIR contract *)
(* --------------- *)

Definition bir_incr_pre_def:
 bir_incr_pre (pre_x10:word64) : bir_exp_t =
  BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x10))
End

Definition bir_incr_post_def:
 bir_incr_post (pre_x10:word64) : bir_exp_t =
  BExp_BinPred
   BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 (pre_x10 + 1w)))
End

(* -------------- *)
(* BSPEC contract *)
(* -------------- *)

Definition bspec_incr_pre_def:
 bspec_incr_pre (pre_x10:word64) : bir_exp_t =
  BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x10))
End

Definition bspec_incr_post_def:
 bspec_incr_post (pre_x10:word64) : bir_exp_t =
  BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_BinExp
      BIExp_Plus (BExp_Const (Imm64 pre_x10)) (BExp_Const (Imm64 1w)))
End

(* -------------------------------------- *)
(* Connecting RISC-V and HL BIR contracts *)
(* -------------------------------------- *)

Theorem incr_riscv_pre_imp_bir_pre_thm:
 bir_pre_riscv_to_bir (riscv_incr_pre pre_x10) (bir_incr_pre pre_x10)
Proof
 rw [bir_pre_riscv_to_bir_def,riscv_incr_pre_def,bir_incr_pre_def] >-
  (rw [bir_is_bool_exp_REWRS,bir_is_bool_exp_env_REWRS] >>
   FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_typing_expTheory.type_of_bir_exp_def]) >>
 FULL_SIMP_TAC (std_ss++holBACore_ss) [riscv_bmr_rel_EVAL,bir_val_TF_bool2b_DEF]
QED

Theorem incr_riscv_post_imp_bir_post_thm:
 !ls. bir_post_bir_to_riscv (riscv_incr_post pre_x10) (\l. bir_incr_post pre_x10) ls
Proof
 once_rewrite_tac [bir_post_bir_to_riscv_def,bir_incr_post_def] >>
 once_rewrite_tac [bir_incr_post_def] >>
 once_rewrite_tac [bir_incr_post_def] >>

 Cases_on `bs` >> Cases_on `b0` >>

 FULL_SIMP_TAC (std_ss++holBACore_ss) [
  bir_envTheory.bir_env_read_def,
  bir_envTheory.bir_env_check_type_def,
  bir_envTheory.bir_env_lookup_type_def,
  bir_envTheory.bir_env_lookup_def,
  bir_eval_bin_pred_def,
  bir_eval_bin_pred_exists_64_eq
 ] >>

 rw [riscv_incr_post_def] >>

 METIS_TAC [riscv_bmr_x10_equiv]
QED

(* ------------------------------------- *)
(* Connecting HL BIR and BSPEC contracts *)
(* ------------------------------------- *)

Theorem incr_bir_pre_imp_bspec_pre_thm[local]:
 bir_exp_is_taut
  (bir_exp_imp (bir_incr_pre pre_x10) (bspec_incr_pre pre_x10))
Proof
 rw [bir_smt_prove_is_taut ``bir_exp_imp (bir_incr_pre pre_x10) (bspec_incr_pre pre_x10)``]
QED

val incr_bir_pre_imp_bspec_pre_eq_thm =
 computeLib.RESTR_EVAL_CONV [``bir_exp_is_taut``,``bir_incr_pre``,``bspec_incr_pre``]
  (concl incr_bir_pre_imp_bspec_pre_thm);

Theorem incr_bir_pre_imp_bspec_pre:
 ^((snd o dest_eq o concl) incr_bir_pre_imp_bspec_pre_eq_thm)
Proof
 rw [GSYM incr_bir_pre_imp_bspec_pre_eq_thm] >>
 ACCEPT_TAC incr_bir_pre_imp_bspec_pre_thm
QED

Theorem incr_bspec_post_imp_bir_post_thm[local]:
 bir_exp_is_taut
  (bir_exp_imp (bspec_incr_post pre_x10) (bir_incr_post pre_x10))
Proof
 rw [bir_smt_prove_is_taut ``bir_exp_imp (bspec_incr_post pre_x10) (bir_incr_post pre_x10)``]
QED

val incr_bspec_post_imp_bir_post_eq_thm =
 computeLib.RESTR_EVAL_CONV [``bir_exp_is_taut``,``bspec_incr_post``,``bir_incr_post``]
 (concl incr_bspec_post_imp_bir_post_thm);

Theorem incr_bspec_post_imp_bir_post:
 ^((snd o dest_eq o concl) incr_bspec_post_imp_bir_post_eq_thm)
Proof
 rw [GSYM incr_bspec_post_imp_bir_post_eq_thm] >>
 ACCEPT_TAC incr_bspec_post_imp_bir_post_thm
QED

val _ = export_theory ();
