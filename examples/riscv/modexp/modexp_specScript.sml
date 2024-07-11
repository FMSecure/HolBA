open HolKernel boolLib Parse bossLib;

open markerTheory;

open distribute_generic_stuffLib;

open bir_bool_expSyntax;
open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;

open bir_riscv_backlifterTheory;
open bir_backlifterLib;
open bir_compositionLib;

open bir_lifting_machinesTheory;
open bir_typing_expTheory;
open bir_htTheory;

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

open bir_env_oldTheory;
open bir_program_varsTheory;

open modexpTheory;

open bir_symbLib;
open distribute_generic_stuffTheory;

val _ = new_theory "modexp_spec";

(* ------------------ *)
(* Program boundaries *)
(* ------------------ *)

Definition modexp_init_addr_def:
 modexp_init_addr : word64 = 0x28w
End

Definition modexp_end_addr_def:
 modexp_end_addr : word64 = 0x24w
End

Definition bspec_modexp_pre_def:
bspec_modexp_pre (x:word64) : bir_exp_t =
 (BExp_Const (Imm1 1w))
End

val _ = export_theory ();
