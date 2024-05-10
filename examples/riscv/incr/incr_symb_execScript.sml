open HolKernel Parse boolLib bossLib;

open bir_symbLib;

open incrTheory;

val _ = new_theory "incr_symb_exec";

(* ---------------------------- *)
(* Program variable definitions *)
(* ---------------------------- *)

Definition incr_prog_vars_def:
  incr_prog_vars = [BVar "x10" (BType_Imm Bit64); BVar "x1" (BType_Imm Bit64)]
End

Definition incr_birenvtyl_def:
  incr_birenvtyl = MAP BVarToPair incr_prog_vars
End

Theorem incr_prog_vars_thm:
  set incr_prog_vars = bir_vars_of_program (bir_incr_prog : 'observation_type bir_program_t)
Proof
  SIMP_TAC (std_ss++HolBASimps.VARS_OF_PROG_ss++pred_setLib.PRED_SET_ss)
   [bir_incr_prog_def, incr_prog_vars_def]
QED

(* ----------------------- *)
(* Symbolic analysis setup *)
(* ----------------------- *)

val bprog_tm = (snd o dest_eq o concl) bir_incr_prog_def;

val birs_state_init_lbl = (snd o dest_eq o concl o EVAL) ``bir_block_pc (BL_Address (Imm64 0x00w))``;

val birs_stop_lbls = [(snd o dest_eq o concl o EVAL) ``bir_block_pc (BL_Address (Imm64 0x4w))``];

val bprog_envtyl = (fst o dest_eq o concl) incr_birenvtyl_def;

val birs_pcond = ``BExp_BinPred
      BIExp_Equal
      (BExp_Den (BVar "sy_x10" (BType_Imm Bit64)))
      (BExp_Const (Imm64 pre_x10))``;

(* --------------------------- *)
(* Symbolic analysis execution *)
(* --------------------------- *)

val result = bir_symb_analysis bprog_tm
 birs_state_init_lbl birs_stop_lbls
 bprog_envtyl birs_pcond;

val _ = show_tags := true;
val _ = Portable.pprint Tag.pp_tag (tag result);

Theorem incr_symb_analysis_thm = result

val _ = export_theory ();