open HolKernel Parse boolLib bossLib;

open wordsTheory;

open bir_symbLib;

open mod2Theory;
open mod2_spec_riscvTheory;
open mod2_spec_birTheory;

val _ = new_theory "mod2_symb_exec";

(* --------------------------- *)
(* prepare program lookups     *)
(* --------------------------- *)

val bir_lift_thm = bir_mod2_riscv_lift_THM;
val _ = birs_auxLib.prepare_program_lookups bir_lift_thm;

(* --------------------------- *)
(* Symbolic analysis execution *)
(* --------------------------- *)

val symb_analysis_thm =
 bir_symb_analysis_thm
  bir_mod2_prog_def
  mod2_init_addr_def [mod2_end_addr_def]
  bspec_mod2_pre_def mod2_birenvtyl_def;

val _ = show_tags := true;

val _ = Portable.pprint Tag.pp_tag (tag symb_analysis_thm);

Theorem mod2_symb_analysis_thm = symb_analysis_thm

val _ = export_theory ();
