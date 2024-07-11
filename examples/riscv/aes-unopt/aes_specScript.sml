open HolKernel boolLib Parse bossLib;

open distribute_generic_stuffLib;

open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory bir_exp_immTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;

open bir_symbLib;

open distribute_generic_stuffTheory;

open aesTheory;

val _ = new_theory "aes_spec";

(* ------------------ *)
(* Program boundaries *)
(* ------------------ *)

Definition aes_init_addr_def:
 aes_init_addr : word64 = 0x0c8w
End

Definition aes_end_addr_def:
 aes_end_addr : word64 = 0x4e4w
End

(* -------------- *)
(* BSPEC contract *)
(* -------------- *)

val vars_of_prog_thm =
(SIMP_CONV (std_ss++HolBASimps.VARS_OF_PROG_ss++pred_setLib.PRED_SET_ss)
   [bir_aes_prog_def] THENC
  EVAL)
 ``bir_vars_of_program (bir_aes_prog : 'observation_type bir_program_t)``;

val all_vars = (pred_setSyntax.strip_set o snd o dest_eq o concl) vars_of_prog_thm;
val registervars = List.filter ((fn s => s <> "MEM8") o (stringSyntax.fromHOLstring o fst o bir_envSyntax.dest_BVar)) all_vars;
val registervars_tm = listSyntax.mk_list (registervars, (type_of o hd) registervars);

Definition bir_aes_registervars_def:
 bir_aes_registervars = ^registervars_tm
End

val bspec_aes_pre_tm = bslSyntax.bandl
 (List.map (mem_addrs_aligned_prog_disj_bir_tm o
   stringSyntax.fromHOLstring o fst o bir_envSyntax.dest_BVar)
  ((fst o listSyntax.dest_list) registervars_tm));

Definition bspec_aes_pre_def:
  bspec_aes_pre : bir_exp_t =
   ^bspec_aes_pre_tm
End

val _ = export_theory ();
