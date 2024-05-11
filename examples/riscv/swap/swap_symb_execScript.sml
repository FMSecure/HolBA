open HolKernel Parse boolLib bossLib;

open bir_symbLib;

open swapTheory;

val _ = new_theory "swap_symb_exec";

(* ---------------------------- *)
(* Program variable definitions *)
(* ---------------------------- *)

Definition swap_prog_vars_def:
  swap_prog_vars = [
    BVar "MEM8" (BType_Mem Bit64 Bit8);
    BVar "x15" (BType_Imm Bit64);
    BVar "x14" (BType_Imm Bit64);
    BVar "x11" (BType_Imm Bit64);
    BVar "x10" (BType_Imm Bit64);
    BVar "x1" (BType_Imm Bit64)
  ]
End

Definition swap_birenvtyl_def:
  swap_birenvtyl = MAP BVarToPair swap_prog_vars
End

Theorem swap_prog_vars_thm:
  set swap_prog_vars = bir_vars_of_program (bir_swap_prog : 'observation_type bir_program_t)
Proof
  SIMP_TAC (std_ss++HolBASimps.VARS_OF_PROG_ss++pred_setLib.PRED_SET_ss)
   [bir_swap_prog_def, swap_prog_vars_def] >>
  EVAL_TAC
QED

(* ----------------------- *)
(* Symbolic analysis setup *)
(* ----------------------- *)

val bprog_tm = (snd o dest_eq o concl) bir_swap_prog_def;

val birs_state_init_lbl = (snd o dest_eq o concl o EVAL) ``bir_block_pc (BL_Address (Imm64 0x00w))``;

val birs_stop_lbls = [(snd o dest_eq o concl o EVAL) ``bir_block_pc (BL_Address (Imm64 0x14w))``];

val bprog_envtyl = (fst o dest_eq o concl) swap_birenvtyl_def;

val birs_pcond = bslSyntax.bandl [
  mem_addrs_aligned_prog_disj_tm "x10",
  mem_addrs_aligned_prog_disj_tm "x11",
  pre_vals_tm "x10" "pre_x10" "pre_x10_mem_deref",
  pre_vals_tm "x11" "pre_x11" "pre_x11_mem_deref"
];

(* --------------------------- *)
(* Symbolic analysis execution *)
(* --------------------------- *)

val result = bir_symb_analysis bprog_tm
 birs_state_init_lbl birs_stop_lbls
 bprog_envtyl birs_pcond;

val _ = show_tags := true;
val _ = Portable.pprint Tag.pp_tag (tag result);

Theorem swap_symb_analysis_thm = result

val _ = export_theory ();
