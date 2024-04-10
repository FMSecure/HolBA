open HolKernel boolLib Parse bossLib;

open markerTheory;

(* FIXME: needed to avoid quse errors *)
open m0_stepLib;

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

open incrTheory;

open incr_symb_execTheory;

val _ = new_theory "incr_prop";

(* --------------- *)
(* RISC-V contract *)
(* --------------- *)

Definition riscv_incr_pre_def:
 riscv_incr_pre x (m : riscv_state) =
  (m.c_gpr m.procID 10w = x)
End

Definition riscv_incr_post_def:
 riscv_incr_post x (m : riscv_state) =
  (m.c_gpr m.procID 10w = x + 1w)
End

(* ------------ *)
(* BIR contract *)
(* ------------ *)

Definition bir_incr_pre_def:
  bir_incr_pre x : bir_exp_t =
  BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 x))
End

Definition bir_incr_post_def:
 bir_incr_post x : bir_exp_t =
  BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 (x + 1w)))
End

(* ----------------------------------- *)
(* Connecting RISC-V and BIR contracts *)
(* ----------------------------------- *)

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
 rw [bir_post_bir_to_riscv_def,riscv_incr_post_def,bir_incr_post_def] >>
 Cases_on `bs` >>
 Cases_on `b0` >>
 FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_envTheory.bir_env_read_def, bir_envTheory.bir_env_check_type_def, bir_envTheory.bir_env_lookup_type_def, bir_envTheory.bir_env_lookup_def,bir_eval_bin_pred_def] >>
 Q.ABBREV_TAC `g = ?z. f "x10" = SOME z ∧ BType_Imm Bit64 = type_of_bir_val z` >>
 Cases_on `g` >-
  (FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_eval_bin_pred_def] >>
   fs [Abbrev_def] >>
   `bir_eval_bin_pred BIExp_Equal (SOME z)
     (SOME (BVal_Imm (Imm64 (pre_x10 + 1w)))) = SOME bir_val_true`
    by METIS_TAC [] >>   
   Cases_on `z` >> fs [type_of_bir_val_def] >>
   FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_eval_bin_pred_def,bir_immTheory.bool2b_def,bir_val_true_def] >>
   FULL_SIMP_TAC (std_ss++holBACore_ss) [bool2w_def] >>
   Q.ABBREV_TAC `bb = bir_bin_pred BIExp_Equal b' (Imm64 (pre_x10 + 1w))` >>
   Cases_on `bb` >> fs [] >>
   FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_exp_immTheory.bir_bin_pred_Equal_REWR] >> 
   FULL_SIMP_TAC (std_ss++holBACore_ss) [riscv_bmr_rel_EVAL,bir_envTheory.bir_env_read_def, bir_envTheory.bir_env_check_type_def, bir_envTheory.bir_env_lookup_type_def, bir_envTheory.bir_env_lookup_def,bir_eval_bin_pred_def]) >>
 FULL_SIMP_TAC (std_ss++holBACore_ss) []
QED

(* ------------------------------- *)
(* BIR symbolic execution analysis *)
(* ------------------------------- *)

val (sys_i, L_s, Pi_f) = (symb_sound_struct_get_sysLPi_fun o concl) incr_symb_analysis_thm;

Definition incr_analysis_L_def:
 incr_analysis_L = ^(L_s)
End

val birs_state_init_lbl = ``<|bpc_label := BL_Address (Imm64 0w); bpc_index := 0|>``;
val birs_state_end_lbl = (snd o dest_eq o concl o EVAL) ``bir_block_pc (BL_Address (Imm64 4w))``;

Definition bprecond_def:
  bprecond = bir_incr_pre
End

val bprecond = (fst o dest_eq o concl) bprecond_def;

Definition bsysprecond_def:
  bsysprecond x = FST (THE (birs_eval_exp (^bprecond x) (bir_senv_GEN_list birenvtyl_riscv)))
End

Theorem bprecond_birs_eval_exp_thm = (computeLib.RESTR_EVAL_CONV [``birs_eval_exp``] THENC
   birs_stepLib.birs_eval_exp_CONV)
     ``birs_eval_exp (bprecond pre_x10) (bir_senv_GEN_list birenvtyl_riscv)``

Theorem bsysprecond_thm =
 (REWRITE_CONV [bsysprecond_def, birs_eval_exp_ALT_thm, bprecond_birs_eval_exp_thm] THENC EVAL) ``bsysprecond pre_x10``

Theorem bprecond_birs_eval_exp_thm2 = REWRITE_CONV [bprecond_birs_eval_exp_thm, GSYM bsysprecond_thm] ``birs_eval_exp (bprecond pre_x10) (bir_senv_GEN_list birenvtyl_riscv)``

val bsysprecond = (fst o dest_eq o concl o Q.SPEC `pre_x10`) bsysprecond_def;

val birs_state_init_pre = ``<|
  bsst_pc       := ^birs_state_init_lbl;
  bsst_environ  := bir_senv_GEN_list birenvtyl_riscv;
  bsst_status   := BST_Running;
  bsst_pcond    := ^bsysprecond
|>``;

val birs_state_ss = rewrites (type_rws ``:birs_state_t``);
val birs_state_init_pre_EQ_thm =
 REWRITE_RULE [] ((REWRITE_CONV [bsysprecond_thm] THENC
  SIMP_CONV (std_ss++birs_state_ss++holBACore_ss) [] THENC
  EVAL)
  ``^((snd o dest_comb) sys_i) = ^birs_state_init_pre``);

val incr_analysis_thm =
  REWRITE_RULE [birs_state_init_pre_EQ_thm, GSYM bir_incr_prog_def] incr_symb_analysis_thm;

Theorem birenvtyl_riscv_EVAL_thm =
 (REWRITE_CONV [birenvtyl_riscv_def, riscv_vars_def,
   bir_lifting_machinesTheory.riscv_bmr_vars_EVAL,
   bir_lifting_machinesTheory.riscv_bmr_temp_vars_EVAL] THENC EVAL) ``birenvtyl_riscv``

val birs_state_thm = REWRITE_CONV [birenvtyl_riscv_EVAL_thm] birs_state_init_pre;

(* ------ *)

(* now the transfer *)

val bprog_tm = (fst o dest_eq o concl) bir_incr_prog_def;

val birs_symb_symbols_f_sound_prog_thm =
  (SPEC (inst [Type`:'observation_type` |-> Type.alpha] bprog_tm) bir_symb_soundTheory.birs_symb_symbols_f_sound_thm);

val birs_prop_transfer_thm =
  (MATCH_MP symb_prop_transferTheory.symb_prop_transfer_thm birs_symb_symbols_f_sound_prog_thm);

Definition bprog_P_def:
  bprog_P x ((SymbConcSt pc st status):(bir_programcounter_t, string, bir_val_t, bir_status_t) symb_concst_t) =
      (status = BST_Running /\
       pc.bpc_index = 0 /\
       bir_envty_list birenvtyl_riscv st /\
       bir_eval_exp (^bprecond x) (BEnv st) = SOME bir_val_true)
End

(* translate the property to BIR state property *)

Theorem bprog_P_thm:
  !x bs.
  bprog_P x (birs_symb_to_concst bs) =
      (bs.bst_status = BST_Running /\
       bs.bst_pc.bpc_index = 0 /\
       bir_envty_list_b birenvtyl_riscv bs.bst_environ /\
       bir_eval_exp (^bprecond x) bs.bst_environ = SOME bir_val_true)
Proof
 REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss) [birs_symb_to_concst_def, bprog_P_def, bir_envty_list_b_thm, bir_BEnv_lookup_EQ_thm]
QED

Definition bprog_Q_def:
  bprog_Q x
     ((SymbConcSt pc1 st1 status1):(bir_programcounter_t, string, bir_val_t, bir_status_t) symb_concst_t)
     ((SymbConcSt pc2 st2 status2):(bir_programcounter_t, string, bir_val_t, bir_status_t) symb_concst_t)
    =
     (
       (pc2 = ^birs_state_end_lbl)
       /\
       (status2 = BST_Running)
       /\
       bir_envty_list birenvtyl_riscv st2 /\
       (st2 "x10" = SOME (BVal_Imm (Imm64 (x + 1w))))
     )
End

Theorem bprog_Q_thm:
  !x bs1 bs2.
  bprog_Q x (birs_symb_to_concst bs1) (birs_symb_to_concst bs2) =
    (
      (bs2.bst_pc = ^birs_state_end_lbl)
      /\
      (bs2.bst_status = BST_Running)
      /\
       bir_envty_list_b birenvtyl_riscv bs2.bst_environ /\
      (bir_env_lookup "x10" bs2.bst_environ = SOME (BVal_Imm (Imm64 (x + 1w))))
    )
Proof
FULL_SIMP_TAC (std_ss) [birs_symb_to_concst_def, bprog_Q_def, bir_envty_list_b_thm]
QED
(* ........................... *)

(* P is generic enough *)

Theorem bprog_P_entails_thm:
  P_entails_an_interpret (bir_symb_rec_sbir ^bprog_tm) (bprog_P pre_x10) (birs_symb_to_symbst ^birs_state_init_pre)
Proof
FULL_SIMP_TAC (std_ss++birs_state_ss) [P_entails_an_interpret_def] >>
  REPEAT STRIP_TAC >>

  ASSUME_TAC ((GSYM o Q.SPEC `s`) birs_symb_to_concst_EXISTS_thm) >>
  FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_EQ_thm] >>

  FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_to_symbst_def, symb_symbst_pc_def] >>

  Cases_on `s` >> Cases_on `st` >>
  FULL_SIMP_TAC (std_ss++holBACore_ss++symb_typesLib.symb_TYPES_ss) [bprog_P_def, birs_symb_to_concst_def, symb_concst_pc_def] >>

  Cases_on `b0` >>
  FULL_SIMP_TAC (std_ss) [bir_envTheory.bir_env_lookup_def] >>
  PAT_X_ASSUM ``A = (\B. C)`` (ASSUME_TAC o GSYM) >>
  FULL_SIMP_TAC (std_ss) [boolTheory.ETA_THM] >>

  `(ALL_DISTINCT (MAP FST birenvtyl_riscv))` by EVAL_TAC >>

  METIS_TAC [bprog_P_entails_gen_thm, birenvtyl_EVAL_thm, bprecond_birs_eval_exp_thm2]
QED

(* ........................... *)


Theorem bir_Pi_overapprox_Q_thm:
  !p P sys Pi Q.
  (Pi_overapprox_Q (bir_symb_rec_sbir p) P (birs_symb_to_symbst sys) (IMAGE birs_symb_to_symbst Pi) Q)
  <=>
  (!sys2 bs bs' H.
     sys2 IN Pi ==>
     birs_symb_matchstate sys H bs ==>
     (\bs. P (birs_symb_to_concst bs)) bs ==>
     (?H'. symb_interpr_ext H' H /\ birs_symb_matchstate sys2 H' bs') ==>
     (\bs bs'. Q (birs_symb_to_concst bs) (birs_symb_to_concst bs')) bs bs')
Proof
FULL_SIMP_TAC (std_ss++birs_state_ss) [Pi_overapprox_Q_def] >>
  REPEAT STRIP_TAC >>

  FULL_SIMP_TAC (std_ss) [symb_matchstate_ext_def, birs_symb_matchstate_EQ_thm] >>

  EQ_TAC >- (
    REPEAT STRIP_TAC >>
    PAT_X_ASSUM ``!x.A`` (ASSUME_TAC o Q.SPECL [`birs_symb_to_symbst sys2`, `birs_symb_to_concst bs`, `birs_symb_to_concst bs'`, `H`]) >>

    REV_FULL_SIMP_TAC (std_ss) [IMAGE_IN, symb_matchstate_ext_def, birs_symb_matchstate_EQ_thm] >>
    METIS_TAC []
  ) >>

  REPEAT STRIP_TAC >>

  `?bsys. sys' = birs_symb_to_symbst bsys` by (
    METIS_TAC [birs_symb_to_symbst_EXISTS_thm]
  ) >>
  `?bs.  s  = birs_symb_to_concst bs /\
   ?bs'. s' = birs_symb_to_concst bs'` by (
    METIS_TAC [birs_symb_to_concst_EXISTS_thm]
  ) >>

  PAT_X_ASSUM ``!x.A`` (ASSUME_TAC o Q.SPECL [`bsys`, `bs`, `bs'`, `H`]) >>

  `bsys IN Pi` by (
    FULL_SIMP_TAC std_ss [] >>

    `birs_symb_from_symbst o birs_symb_to_symbst = I` by (
      SIMP_TAC std_ss [combinTheory.o_DEF, bir_symbTheory.birs_symb_to_from_symbst_thm] >>
      MATCH_MP_TAC boolTheory.EQ_EXT >>
      SIMP_TAC std_ss [combinTheory.I_THM]
    ) >>
    METIS_TAC [IMAGE_IN, IMAGE_IMAGE, bir_symbTheory.birs_symb_to_from_symbst_thm, IMAGE_I]
  ) >>

  FULL_SIMP_TAC (std_ss) [symb_matchstate_ext_def, birs_symb_matchstate_EQ_thm] >>
  REV_FULL_SIMP_TAC (std_ss) [symb_matchstate_ext_def, birs_symb_matchstate_EQ_thm] >>
  METIS_TAC []
QED


(* Q is implied by sys and Pi *)
Theorem bprog_Pi_overapprox_Q_thm:
  Pi_overapprox_Q (bir_symb_rec_sbir ^bprog_tm) (bprog_P pre_x10) (birs_symb_to_symbst ^birs_state_init_pre) ^Pi_f(*(IMAGE birs_symb_to_symbst {a;b;c;d})*) (bprog_Q pre_x10)
Proof
REWRITE_TAC [bir_Pi_overapprox_Q_thm] >>
  REPEAT GEN_TAC >>

  REWRITE_TAC [pred_setTheory.IMAGE_INSERT, pred_setTheory.IMAGE_EMPTY, pred_setTheory.IN_INSERT, pred_setTheory.NOT_IN_EMPTY] >>
  STRIP_TAC >> (
    POP_ASSUM (fn thm => (ASSUME_TAC thm >> Q.ABBREV_TAC `sys3 = ^((snd o dest_eq o concl) thm)`)) >>
    ASM_SIMP_TAC std_ss [] >>
    rename1 `sys4 = sys3` >>
    rename1 `sys4 = sys2` >>
    PAT_X_ASSUM ``A = B`` (K ALL_TAC) >>

    DISCH_TAC >>
    POP_ASSUM (fn thm => (ASSUME_TAC thm >> Q.ABBREV_TAC `sys1 = ^((snd o dest_comb o fst o dest_comb o fst o dest_comb o concl) thm)`)) >>
    POP_ASSUM (fn thm0 => POP_ASSUM (fn thm1 => (ASSUME_TAC thm0 >> ASSUME_TAC thm1))) >>
    REPEAT STRIP_TAC >>

    (* now the proof state is somewhat clean *)

    FULL_SIMP_TAC (std_ss) [bprog_Q_thm] >>
    (* pc *)
    CONJ_TAC >- (
      Q.UNABBREV_TAC `sys2` >>
      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
    ) >>
    (* status Running *)
    CONJ_TAC >- (
      Q.UNABBREV_TAC `sys2` >>
      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
    ) >>

    (* bir_envty_list_b *)
    CONJ_TAC >- (
      Q.UNABBREV_TAC `sys2` >>
      cheat
    ) >>

    (* the property (here: pre_x10 + 1) *)
    `BVar "sy_x10" (BType_Imm Bit64) IN symb_interpr_dom H` by (
      `symb_interpr_for_symbs (birs_symb_symbols sys1) H` by (
        FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
      ) >>

      Q.UNABBREV_TAC `sys1` >>
      POP_ASSUM (ASSUME_TAC o CONV_RULE (
          REWRITE_CONV [bsysprecond_thm, birenvtyl_EVAL_thm] THENC
          computeLib.RESTR_EVAL_CONV [``birs_symb_symbols``] THENC
          aux_setLib.birs_symb_symbols_MATCH_CONV)
        ) >>

      FULL_SIMP_TAC (std_ss) [symb_interpr_for_symbs_def, INSERT_SUBSET]
    ) >>
    `BVar "sy_x10" (BType_Imm Bit64) IN symb_interpr_dom H'` by (
      `symb_interpr_for_symbs (birs_symb_symbols sys2) H'` by (
        FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
      ) >>

      Q.UNABBREV_TAC `sys2` >>
      POP_ASSUM (ASSUME_TAC o CONV_RULE (
          REWRITE_CONV [bsysprecond_thm, birenvtyl_EVAL_thm] THENC
          computeLib.RESTR_EVAL_CONV [``birs_symb_symbols``] THENC
          aux_setLib.birs_symb_symbols_MATCH_CONV)
        ) >>

      FULL_SIMP_TAC (std_ss) [symb_interpr_for_symbs_def, INSERT_SUBSET]
    ) >>

    `symb_interpr_get H' (BVar "sy_x10" (BType_Imm Bit64)) = symb_interpr_get H (BVar "sy_x10" (BType_Imm Bit64))` by (
      FULL_SIMP_TAC std_ss [symb_interpr_ext_def, symb_interprs_eq_for_def]
    ) >>

    `bir_eval_exp (bprecond pre_x10) bs.bst_environ = SOME bir_val_true` by (
      Q.UNABBREV_TAC `sys1` >>
      FULL_SIMP_TAC (std_ss) [bprog_P_thm]
    ) >>

    (* use bprog_P *)
    `symb_interpr_get H (BVar "sy_x10" (BType_Imm Bit64)) = SOME (BVal_Imm (Imm64 pre_x10))` by (
      FULL_SIMP_TAC (std_ss) [bprog_P_thm] >>
      `bir_env_lookup "x10" bs.bst_environ = SOME (BVal_Imm (Imm64 pre_x10))` by (
        cheat
      ) >>

      cheat
(*
      Q.UNABBREV_TAC `sys1` >>
      Q.UNABBREV_TAC `sys2` >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def] >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_matchenv_def] >>
      REPEAT (PAT_X_ASSUM ``!A.B`` (ASSUME_TAC o EVAL_RULE o Q.SPEC `"x10"`)) >>
      FULL_SIMP_TAC (std_ss) [] >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_interpr_welltyped_def] >>
      REPEAT (PAT_X_ASSUM ``!A.B`` (ASSUME_TAC o EVAL_RULE o Q.SPEC `BVar "sy_x10" (BType_Imm Bit64)`)) >>
      FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>
      REV_FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>

      Cases_on `symb_interpr_get H (BVar "sy_x10" (BType_Imm Bit64))` >- (
        METIS_TAC [symb_interpr_dom_IMP_get_CASES_thm, optionTheory.option_CLAUSES]
      ) >>
      FULL_SIMP_TAC (std_ss++holBACore_ss) [optionTheory.option_CLAUSES] >>

      `bir_val_is_Imm_s Bit64 x` by (
        METIS_TAC [bir_valuesTheory.bir_val_checker_TO_type_of]
      ) >>
      FULL_SIMP_TAC std_ss [bir_valuesTheory.bir_val_is_Imm_s_def, bir_immTheory.n2bs_def] >>

      FULL_SIMP_TAC (std_ss++holBACore_ss) []
*)
    ) >>

    (* *)
    cheat
(*
    `(?v.
       bir_env_lookup "countw" bs.bst_environ = SOME v /\
       birs_interpret_fun H (THE (sys1.bsst_environ "countw")) = SOME v) /\
     (?v'.
       bir_env_lookup "countw" bs'.bst_environ = SOME v' /\
       birs_interpret_fun H' (THE (sys2.bsst_environ "countw")) = SOME v')` by (
      Q.UNABBREV_TAC `sys1` >>
      Q.UNABBREV_TAC `sys2` >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def] >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_matchenv_def] >>
      REPEAT (PAT_X_ASSUM ``!A.B`` (ASSUME_TAC o EVAL_RULE o Q.SPEC `"countw"`)) >>
      FULL_SIMP_TAC (std_ss) [] >>

      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_interpr_welltyped_def] >>
      REPEAT (PAT_X_ASSUM ``!A.B`` (ASSUME_TAC o EVAL_RULE o Q.SPEC `BVar "sy_countw" (BType_Imm Bit64)`)) >>
      FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>
      REV_FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>

      Cases_on `symb_interpr_get H (BVar "sy_countw" (BType_Imm Bit64))` >- (
        METIS_TAC [symb_interpr_dom_IMP_get_CASES_thm, optionTheory.option_CLAUSES]
      ) >>
      FULL_SIMP_TAC (std_ss++holBACore_ss) [optionTheory.option_CLAUSES] >>

      FULL_SIMP_TAC (std_ss++holBACore_ss) [birs_auxTheory.birs_gen_env_GET_thm, birs_auxTheory.birs_gen_env_GET_NULL_thm] >>
      ASM_REWRITE_TAC [birs_interpret_fun_def, birs_interpret_subst_def, birs_interpret_subst_fmap_def, bir_typing_expTheory.bir_vars_of_exp_def, bir_envTheory.bir_env_empty_def, bir_envTheory.bir_env_map_empty_def] >>

      computeLib.RESTR_EVAL_TAC [``bir_exp_subst``] >>
      ASM_REWRITE_TAC []
    ) >>

    REPEAT (PAT_X_ASSUM ``birs_symb_matchstate A B C`` (K ALL_TAC)) >>
    Q.UNABBREV_TAC `sys1` >>
    Q.UNABBREV_TAC `sys2` >>
    FULL_SIMP_TAC (std_ss++birs_state_ss) [] >>
    FULL_SIMP_TAC (std_ss++holBACore_ss) [birs_auxTheory.birs_gen_env_GET_thm, birs_auxTheory.birs_gen_env_GET_NULL_thm] >>
    (* now the proof state is pretty much cleaned up *)

    FULL_SIMP_TAC std_ss [birs_interpret_fun_thm] >>
    REPEAT (PAT_X_ASSUM ``birs_interpret_fun_ALT A B = SOME C`` (ASSUME_TAC o computeLib.RESTR_EVAL_RULE [])) >>
    FULL_SIMP_TAC std_ss [] >>
    REV_FULL_SIMP_TAC std_ss [] >>
    FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>

    PAT_X_ASSUM ``BVal_Imm (Imm64 A) = B`` (ASSUME_TAC o GSYM) >>
    FULL_SIMP_TAC (std_ss++holBACore_ss) [] >>

    (* still have to unpack the precondition for the space fact about countw *)
    FULL_SIMP_TAC (std_ss++holBACore_ss) [bprecond_def] >>
    REPEAT (PAT_X_ASSUM ``bir_eval_bin_exp BIExp_And A B = SOME bir_val_true`` (ASSUME_TAC o MATCH_MP birs_rulesTheory.bir_conj_true) >> FULL_SIMP_TAC std_ss []) >>
    IMP_RES_TAC bir_env_read_countw_lookup_thm >>
    FULL_SIMP_TAC (std_ss++holBACore_ss) [bir_bool_expTheory.bir_val_TF_bool2b_DEF] >>
    PAT_X_ASSUM ``v1 <=+ A`` (MP_TAC) >>
    REPEAT (POP_ASSUM (K ALL_TAC)) >>

(*
    now we are only left with the word relation
*)

    HolSmtLib.Z3_ORACLE_TAC
*)
  )
QED
(* ........................... *)

(* apply the theorem for property transfer *)
val bprog_prop_holds_thm =
  MATCH_MP
    (MATCH_MP
      (MATCH_MP
         birs_prop_transfer_thm
         bprog_P_entails_thm)
      bprog_Pi_overapprox_Q_thm)
    incr_analysis_thm;

(* lift to concrete state property *)
val bprog_concst_prop_thm =
  SIMP_RULE (std_ss++birs_state_ss)
    [birs_symb_symbst_pc_thm]
    (REWRITE_RULE
      [symb_prop_transferTheory.prop_holds_def]
      bprog_prop_holds_thm);
(* ........................... *)


(* lift to concrete bir property *)
val st_init_lbl = (snd o dest_eq o hd o fst o strip_imp o snd o strip_forall o concl) bprog_concst_prop_thm;
(* TODO: we probably need a better way to "summarize/overapproximate" the labels of the program, check that this is possible and none of the rules break this *)
val bprog_lbls  = List.nth ((snd o strip_comb o fst o dest_conj o snd o strip_exists o snd o strip_imp o snd o strip_forall o concl) bprog_concst_prop_thm, 3);
Theorem bprog_to_concst_prop_thm:
  !st.
  (symb_concst_pc (birs_symb_to_concst st) = (^st_init_lbl)) ==>
  (bprog_P pre_x10 (birs_symb_to_concst st)) ==>
  (?n st'.
     (step_n_in_L
       (symb_concst_pc o birs_symb_to_concst)
       (SND o bir_exec_step (^bprog_tm))
       st
       n
       (^bprog_lbls)
       st')
     /\
     (bprog_Q pre_x10 (birs_symb_to_concst st) (birs_symb_to_concst st')))
Proof
REPEAT STRIP_TAC >>
  IMP_RES_TAC (HO_MATCH_MP birs_symb_to_concst_PROP_FORALL_thm bprog_concst_prop_thm) >>

  FULL_SIMP_TAC (std_ss++symb_typesLib.symb_TYPES_ss) [conc_step_n_in_L_def, bir_symb_rec_sbir_def] >>

  ASSUME_TAC ((GSYM o Q.SPEC `s'`) birs_symb_to_concst_EXISTS_thm) >>
  FULL_SIMP_TAC std_ss [] >>
  FULL_SIMP_TAC std_ss [] >>

  `birs_symb_to_concst o SND o bir_exec_step ^bprog_tm o
             birs_symb_from_concst =
   birs_symb_to_concst o (SND o bir_exec_step ^bprog_tm) o
             birs_symb_from_concst` by (
    FULL_SIMP_TAC (std_ss) []
  ) >>
  FULL_SIMP_TAC (pure_ss) [] >>

  FULL_SIMP_TAC (pure_ss) [
    SIMP_RULE std_ss [birs_symb_to_from_concst_thm, birs_symb_to_concst_EXISTS_thm, birs_symb_to_concst_EQ_thm] (
      SPECL [``birs_symb_to_concst``, ``birs_symb_from_concst``] (
        INST_TYPE [Type`:'b` |-> Type`:(bir_programcounter_t, string, bir_val_t, bir_status_t) symb_concst_t`, Type`:'a` |-> Type`:bir_state_t`] step_n_in_L_ABS_thm)
  )] >>

  METIS_TAC []
QED

(* finish translation to pure BIR property *)
Theorem bprog_bir_prop_thm = REWRITE_RULE
    [bprog_P_thm, bprecond_def, bprog_Q_thm, birs_symb_concst_pc_thm, combinTheory.o_DEF, GSYM bir_programTheory.bir_exec_step_state_def, GSYM incr_analysis_L_def]
    (REWRITE_RULE
      []
      bprog_to_concst_prop_thm)

(* ........................... *)

val bir_frag_l_tm = ``<|bpc_label := BL_Address (Imm64 0w); bpc_index := 0|>``;
val bir_frag_l_ml_tm = (snd o dest_comb o snd o dest_comb o snd o dest_eq o concl o EVAL) ``(^bir_frag_l_tm).bpc_label``;

val bir_frag_l_exit_ml_tm = ``4w:word64``;
val bir_frag_l_exit_tm = ``<|bpc_label := BL_Address (Imm64 ^bir_frag_l_exit_ml_tm); bpc_index := 0|>``;

Definition pre_bir_def:
  pre_bir x bs =
       (bir_eval_exp (bprecond x) bs.bst_environ = SOME bir_val_true)
End

Definition post_bir_def:
  post_bir x bs1 bs2 =
      (bir_env_lookup "x10" bs2.bst_environ = SOME (BVal_Imm (Imm64 (x + 1w))))
End

Definition pre_bir_nL_def:
  pre_bir_nL x st =
      (
       st.bst_status = BST_Running /\
       st.bst_pc.bpc_index = 0 /\
       bir_envty_list_b birenvtyl_riscv st.bst_environ /\

       pre_bir x st
      )
End
Definition post_bir_nL_def:
  post_bir_nL x (st:bir_state_t) st' =
      (
         (st'.bst_pc = ^bir_frag_l_exit_tm) /\
         st'.bst_status = BST_Running /\
         bir_envty_list_b birenvtyl_riscv st'.bst_environ /\

         post_bir x st st'
      )
End

Theorem bir_step_n_in_L_jgmt_thm[local]:
  bir_step_n_in_L_jgmt
  ^bprog_tm
  ^bir_frag_l_tm
  incr_analysis_L
  (pre_bir_nL pre_x10)
  (post_bir_nL pre_x10)
Proof
REWRITE_TAC [bir_step_n_in_L_jgmt_def] >>
  REWRITE_TAC [pre_bir_nL_def, pre_bir_def, bprecond_def] >>
  REPEAT STRIP_TAC >>

  ASSUME_TAC (Q.SPEC `st` bprog_bir_prop_thm) >>
  REV_FULL_SIMP_TAC std_ss [] >>

  FULL_SIMP_TAC std_ss [
     prove(``(\x. bir_exec_step_state ^(bprog_tm) x) = bir_exec_step_state ^(bprog_tm)``, MATCH_MP_TAC boolTheory.EQ_EXT >> SIMP_TAC std_ss [])
    ] >>
  Q.EXISTS_TAC `n` >>
  Q.EXISTS_TAC `st'` >>
  ASM_SIMP_TAC std_ss [] >>

  REWRITE_TAC [post_bir_nL_def, post_bir_def] >>
  ASM_SIMP_TAC (std_ss++holBACore_ss) []
QED


Theorem incr_analysis_L_INTER_thm[local]:
  incr_analysis_L INTER
        {<|bpc_label := BL_Address (Imm64 4w); bpc_index := 0|>} =
        EMPTY
Proof
`!A B. A INTER {B} = (EMPTY:bir_programcounter_t -> bool) <=> B NOTIN A` by (
    REPEAT STRIP_TAC >>
    EQ_TAC >> (
      FULL_SIMP_TAC std_ss [bir_auxiliaryTheory.SING_DISJOINT_SING_NOT_IN_thm]
    ) >>
    REPEAT STRIP_TAC >>

    REWRITE_TAC [Once (GSYM INTER_COMM)] >>
    FULL_SIMP_TAC std_ss [INTER_EMPTY, INSERT_INTER]
  ) >>
  POP_ASSUM (fn thm => ASM_REWRITE_TAC [thm]) >>

  EVAL_TAC
QED

Theorem bir_abstract_jgmt_rel_incr_thm[local]:
  abstract_jgmt_rel
  (bir_ts ^bprog_tm)
  (BL_Address (Imm64 ^bir_frag_l_ml_tm))
  {BL_Address (Imm64 ^bir_frag_l_exit_ml_tm)}
  (pre_bir_nL pre_x10)
  (post_bir_nL pre_x10)
Proof
ASSUME_TAC
    (Q.SPEC `{BL_Address (Imm64 ^bir_frag_l_exit_ml_tm)}`
      (MATCH_MP
        (REWRITE_RULE
           [bir_programTheory.bir_block_pc_def]
           bir_program_transfTheory.bir_step_n_in_L_jgmt_TO_abstract_jgmt_rel_thm)
        bir_step_n_in_L_jgmt_thm)) >>

  FULL_SIMP_TAC std_ss [pre_bir_nL_def] >>

  FULL_SIMP_TAC std_ss [IMAGE_SING, IN_SING, bir_programTheory.bir_block_pc_def] >>
  FULL_SIMP_TAC (std_ss++holBACore_ss) [incr_analysis_L_INTER_thm] >>

  FULL_SIMP_TAC std_ss [post_bir_nL_def] >>
  FULL_SIMP_TAC (std_ss++holBACore_ss) [abstract_jgmt_rel_def]
QED

Theorem bir_envty_list_b_incr_thm[local]:
  !env. bir_envty_list_b birenvtyl_riscv env ==>
        bir_env_vars_are_initialised env (bir_vars_of_program ^bprog_tm)
Proof
  REWRITE_TAC [birenvtyl_riscv_def, GSYM incr_prog_vars_thm] >>
(*
  bir_envty_list_b_thm
  bir_envty_list_MEM_IMP_thm
  bir_envty_list_NOT_MEM_IMP_thm
  *)
  cheat
QED

Theorem abstract_jgmt_rel_incr[local]:
 abstract_jgmt_rel (bir_ts ^bprog_tm) (BL_Address (Imm64 0w)) {BL_Address (Imm64 4w)}
  (\st. bir_exec_to_labels_triple_precond st (bir_incr_pre pre_x10) ^bprog_tm)
  (\st st'. bir_exec_to_labels_triple_postcond st' (\l. if l = BL_Address (Imm64 4w) then (bir_incr_post pre_x10) else bir_exp_false) ^bprog_tm)
Proof
  (* reasoning via symb_prop_transfer_thm goes here *)
  ASSUME_TAC bir_abstract_jgmt_rel_incr_thm >>

  FULL_SIMP_TAC std_ss [abstract_jgmt_rel_def, bir_exec_to_labels_triple_precond_def] >>
  FULL_SIMP_TAC std_ss [pre_bir_nL_def, pre_bir_def, bprecond_def, post_bir_nL_def, post_bir_def] >>

  REPEAT STRIP_TAC >>
  PAT_X_ASSUM ``!x. A`` (ASSUME_TAC o Q.SPECL [`st`]) >>
  REV_FULL_SIMP_TAC (std_ss) [] >>
  `bir_envty_list_b birenvtyl_riscv st.bst_environ` by (
    cheat (* FIXME: this cannot be proved *)
  ) >>
  FULL_SIMP_TAC std_ss [] >>
  REV_FULL_SIMP_TAC std_ss [] >>

  Q.EXISTS_TAC `ms'` >>
  ASM_REWRITE_TAC [] >>

  FULL_SIMP_TAC (std_ss++HolBACoreSimps.holBACore_ss) [bir_exec_to_labels_triple_postcond_def] >>
  ASM_SIMP_TAC std_ss [bir_envty_list_b_incr_thm] >>

  REWRITE_TAC [bir_incr_post_def] >>
  FULL_SIMP_TAC (std_ss++HolBACoreSimps.holBACore_ss) [] >>

  FULL_SIMP_TAC (std_ss++HolBACoreSimps.holBACore_ss) [bir_envTheory.bir_env_read_def, bir_envTheory.bir_env_check_type_def, bir_envTheory.bir_env_lookup_type_def, EVAL ``bool2b T``, bir_val_true_def] >>

  IMP_RES_TAC bir_envty_list_b_incr_thm >>
  FULL_SIMP_TAC std_ss [] >>
  (*FULL_SIMP_TAC std_ss [GSYM bir_envty_list_b_incr_thm] >>*)
  REWRITE_TAC [bir_bool_expTheory.bir_is_bool_exp_env_REWRS, bir_typing_expTheory.bir_vars_of_exp_def] >>
  FULL_SIMP_TAC (std_ss++HolBACoreSimps.holBACore_ss) [] >>

  FULL_SIMP_TAC (std_ss++HolBASimps.VARS_OF_PROG_ss++pred_setLib.PRED_SET_ss) [GSYM incr_prog_vars_thm, incr_prog_vars_def] >>

  FULL_SIMP_TAC std_ss [bir_env_oldTheory.bir_env_vars_are_initialised_INSERT, bir_env_oldTheory.bir_env_vars_are_initialised_EMPTY]
QED

Theorem bir_cont_incr[local]:
 bir_cont ^bprog_tm bir_exp_true (BL_Address (Imm64 0w))
  {BL_Address (Imm64 4w)} {} (bir_incr_pre pre_x10)
  (\l. if l = BL_Address (Imm64 4w) then (bir_incr_post pre_x10) else bir_exp_false)
Proof
 `{BL_Address (Imm64 4w)} <> {}` by fs [] >>
 MP_TAC ((Q.SPECL [
  `BL_Address (Imm64 0w)`,
  `{BL_Address (Imm64 4w)}`,
  `bir_incr_pre pre_x10`,
  `\l. if l = BL_Address (Imm64 4w) then (bir_incr_post pre_x10) else bir_exp_false`
 ] o SPEC bprog_tm o INST_TYPE [Type.alpha |-> Type`:'observation_type`]) abstract_jgmt_rel_bir_cont) >>
 rw [] >>
 METIS_TAC [abstract_jgmt_rel_incr]
QED

(* TODO: RISC-V backlifting *)

val _ = export_theory ();
