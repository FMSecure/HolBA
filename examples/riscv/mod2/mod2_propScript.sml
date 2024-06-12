open HolKernel boolLib Parse bossLib;

open markerTheory;

open numTheory arithmeticTheory int_bitwiseTheory;
open pairTheory combinTheory wordsTheory;

open distribute_generic_stuffLib;

open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;

open bir_riscv_backlifterTheory;
open bir_backlifterLib;
open bir_compositionLib;

open bir_wpLib bir_wp_expLib;
open bir_wpTheory bir_htTheory;
open bir_wp_interfaceLib;

open tutorial_smtSupportLib;

open bir_symbTheory birs_auxTheory;
open HolBACoreSimps;
open bir_program_transfTheory;

open total_program_logicTheory;
open total_ext_program_logicTheory;
open symb_prop_transferTheory;

open jgmt_rel_bir_contTheory;

open bir_symbTheory;
open birs_stepLib;
open bir_symb_sound_coreTheory;
open symb_recordTheory;
open symb_interpretTheory;

open pred_setTheory;

open program_logicSimps;

open distribute_generic_stuffTheory;

open mod2Theory;
open mod2_specTheory;
open mod2_symb_transfTheory;

val _ = new_theory "mod2_prop";

(* --------------- *)
(* HL BIR contract *)
(* --------------- *)

val end_addr_tm = (snd o dest_eq o concl) mod2_end_addr_def;

val bir_cont_mod2_thm = use_post_weak_rule_simp
 (use_pre_str_rule_simp bspec_cont_mod2 mod2_bir_pre_imp_bspec_pre)
 ``BL_Address (Imm64 ^end_addr_tm)``
 mod2_bspec_post_imp_bir_post;

Theorem bir_cont_mod2:
 bir_cont bir_mod2_prog bir_exp_true
  (BL_Address (Imm64 mod2_init_addr)) {BL_Address (Imm64 mod2_end_addr)} {}
  (bir_mod2_pre pre_x10)
  (\l. if l = BL_Address (Imm64 mod2_end_addr)
       then (bir_mod2_post pre_x10)
       else bir_exp_false)
Proof
 rw [mod2_init_addr_def,mod2_end_addr_def] >>
 ACCEPT_TAC bir_cont_mod2_thm
QED

(* ---------------------------------- *)
(* Backlifting BIR contract to RISC-V *)
(* ---------------------------------- *)

val riscv_cont_mod2_thm =
 get_riscv_contract_sing
  bir_cont_mod2
  ``bir_mod2_progbin``
  ``riscv_mod2_pre pre_x10`` ``riscv_mod2_post pre_x10`` bir_mod2_prog_def
  [bir_mod2_pre_def]
  bir_mod2_pre_def mod2_riscv_pre_imp_bir_pre_thm
  [bir_mod2_post_def] mod2_riscv_post_imp_bir_post_thm
  bir_mod2_riscv_lift_THM;

Theorem riscv_cont_mod2:
 riscv_cont bir_mod2_progbin mod2_init_addr {mod2_end_addr}
  (riscv_mod2_pre pre_x10) (riscv_mod2_post pre_x10)
Proof
 ACCEPT_TAC riscv_cont_mod2_thm
QED

(* ------------------------ *)
(* Unfolded RISC-V contract *)
(* ------------------------ *)

val readable_thm = computeLib.RESTR_EVAL_CONV [``riscv_weak_trs``] (concl riscv_cont_mod2);

Theorem riscv_cont_mod2_full:
  !pre_x10. ^((snd o dest_eq o concl) readable_thm)
Proof
 METIS_TAC [riscv_cont_mod2, readable_thm]
QED

val _ = export_theory ();
