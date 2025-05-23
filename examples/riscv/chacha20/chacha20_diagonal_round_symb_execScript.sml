open HolKernel Parse boolLib bossLib;

open wordsTheory;

open bir_symbLib;

open chacha20Theory;
open chacha20_spec_riscvTheory;
open chacha20_spec_birTheory;

val _ = new_theory "chacha20_diagonal_round_symb_exec";

(* --------------------------- *)
(* prepare program lookups     *)
(* --------------------------- *)

val bir_lift_thm = bir_chacha20_riscv_lift_THM;
val _ = birs_auxLib.prepare_program_lookups bir_lift_thm;

(* --------------------------- *)
(* Symbolic analysis execution *)
(* --------------------------- *)

val _ = show_tags := true;

(* ------------ *)
(* diagonal round *)
(* ------------ *)

val symb_analysis_thm =
 bir_symb_analysis_thm
  bir_chacha20_prog_def
  chacha20_diagonal_round_init_addr_def [chacha20_diagonal_round_end_addr_def]
  bspec_chacha20_diagonal_round_pre_def chacha20_birenvtyl_def;

val _ = Portable.pprint Tag.pp_tag (tag symb_analysis_thm);

Theorem chacha20_diagonal_round_symb_analysis_thm = symb_analysis_thm

val _ = export_theory ();
