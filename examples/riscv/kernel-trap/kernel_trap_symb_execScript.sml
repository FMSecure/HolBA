open HolKernel Parse boolLib bossLib;

open wordsTheory;

open bir_symbLib;

open kernel_trapTheory;
open kernel_trap_spec_riscvTheory;
open kernel_trap_spec_birTheory;

val _ = new_theory "kernel_trap_symb_exec";

(* --------------------------- *)
(* prepare program lookups     *)
(* --------------------------- *)

val bir_lift_thm = bir_kernel_trap_riscv_lift_THM;
val _ = birs_auxLib.prepare_program_lookups bir_lift_thm;

(* --------------------------- *)
(* Symbolic analysis execution *)
(* --------------------------- *)

val _ = show_tags := true;

(* ---------- *)
(* trap entry *)
(* ---------- *)

val symb_analysis_thm =
 bir_symb_analysis_thm
  bir_kernel_trap_prog_def
  kernel_trap_entry_init_addr_def [kernel_trap_entry_end_addr_def]
  bspec_kernel_trap_entry_pre_def kernel_trap_birenvtyl_def;

val _ = Portable.pprint Tag.pp_tag (tag symb_analysis_thm);

Theorem kernel_trap_entry_symb_analysis_thm = symb_analysis_thm

(* ----------- *)
(* trap return *)
(* ----------- *)

val symb_analysis_thm =
 bir_symb_analysis_thm
  bir_kernel_trap_prog_def
  kernel_trap_return_init_addr_def [kernel_trap_return_end_addr_def]
  bspec_kernel_trap_return_pre_def kernel_trap_birenvtyl_def;

val _ = Portable.pprint Tag.pp_tag (tag symb_analysis_thm);

Theorem kernel_trap_return_symb_analysis_thm = symb_analysis_thm

val _ = export_theory ();
