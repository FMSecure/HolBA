open HolKernel boolLib Parse bossLib;

open markerTheory;

open wordsTheory;

open bir_programSyntax bir_program_labelsTheory;
open bir_immTheory bir_valuesTheory bir_expTheory;
open bir_tsTheory bir_bool_expTheory bir_programTheory;

open bir_riscv_backlifterTheory;
open bir_backlifterLib;
open bir_compositionLib;

open bir_lifting_machinesTheory;
open bir_typing_expTheory;
open bir_htTheory;

open bir_predLib;
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

val _ = new_theory "chacha_spec";

(* ------------- *)
(* ChaCha theory *)
(* ------------- *)

(*
op line (a:idx) (b:idx) (d:idx) (s:int) (m:state) : state =
  let m = m.[a <- (m.[a] + m.[b])] in
  let m = m.[d <- W32.rol (m.[d] +^ m.[a]) s] in m.
*)

Type chacha_state = ``:word32 # word32 # word32 # word32 #
                       word32 # word32 # word32 # word32 #
                       word32 # word32 # word32 # word32 #
                       word32 # word32 # word32 # word32``

Type chacha_row = ``:word32 # word32 # word32 # word32``

Definition chacha_line:
 chacha_line ((a0,b0,c0,d0):chacha_row) : chacha_row =
  let a1 = a0 + b0 in
  let d1 = d0 ?? a1 in
  (a1, b0, c0, d1)
End

(* ---------------- *)
(* Block boundaries *)
(* ---------------- *)

(* keysetup *)

Definition chacha_keysetup_init_addr_def:
 chacha_keysetup_init_addr : word64 = 0x10488w
End

Definition chacha_keysetup_end_addr_def:
 chacha_keysetup_end_addr : word64 = (*0x106a8w*) 0x1053cw
End

(* ivsetup *)

Definition chacha_ivsetup_init_addr_def:
 chacha_ivsetup_init_addr : word64 = 0x106bcw
End

Definition chacha_ivsetup_end_addr_def:
 chacha_ivsetup_end_addr : word64 = 0x10778w
End

(* quarterround *)

Definition chacha_quarterround_init_addr_def:
  chacha_quarterround_init_addr : word64 = 0x108a0w
End

Definition chacha_quarterround_end_addr_def:
 chacha_quarterround_end_addr : word64 = 0x108b4w
End

(* --------------- *)
(* BSPEC contracts *)
(* --------------- *)

(* keysetup *)

val bspec_chacha_keysetup_pre_tm = bslSyntax.bandl [
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x10",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x11"
];

Definition bspec_chacha_keysetup_pre_def:
 bspec_chacha_keysetup_pre : bir_exp_t =
  ^bspec_chacha_keysetup_pre_tm
End

(* ivsetup *)

val bspec_chacha_ivsetup_pre_tm = bslSyntax.bandl [
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x10",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x11"
];

Definition bspec_chacha_ivsetup_pre_def:
 bspec_chacha_ivsetup_pre : bir_exp_t =
  ^bspec_chacha_ivsetup_pre_tm
End

(* quarterround *)

val bspec_chacha_quarterround_pre_tm = bslSyntax.bandl [
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x10",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x11",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x12"
];

Definition bspec_chacha_quarterround_pre_def:
 bspec_chacha_quarterround_pre : bir_exp_t =
  ^bspec_chacha_quarterround_pre_tm
End

val _ = export_theory ();
