structure distribute_generic_stuffLib =
struct

open Abbrev;

local 
  open HolKernel Parse boolLib bossLib;
  
  open holba_convLib;

  open HolBACoreSimps;
  open bir_env_oldTheory;
  open bir_envTheory;
  open birs_auxTheory;
  open distribute_generic_stuffTheory;
  open bir_symb_sound_coreTheory;

  open birsSyntax;

  val birs_state_ss = rewrites (type_rws ``:birs_state_t``);

in


(* TODO: MOVE AWAY !!!!! GENERIC DEFINITIONS AND THEOREMS *)
(*
val varset_thm = incr_prog_vars_thm;
*)
fun Q_bircont_SOLVE3CONJS_TAC varset_thm = (
    FULL_SIMP_TAC (std_ss) [Q_bircont_thm] >>
    (* pc *)
    CONJ_TAC >- (
      REV_FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
    ) >>
    (* status Running *)
    CONJ_TAC >- (
      REV_FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def]
    ) >>

    (* bir_env_vars_are_initialised *)
    CONJ_TAC >- (
      PAT_X_ASSUM ``A = B`` (fn thm => FULL_SIMP_TAC std_ss [thm]) >>
      PAT_X_ASSUM ``A = B`` (K ALL_TAC) >>
      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_matchstate_def, varset_thm] >>

      IMP_RES_TAC birs_env_vars_are_initialised_IMP_thm >>
      POP_ASSUM (K ALL_TAC) >>
      PAT_X_ASSUM ``!x. A`` (ASSUME_TAC o SPEC ((snd o dest_eq o concl) varset_thm)) >>
      POP_ASSUM (MATCH_MP_TAC) >>

      (* cleanup proof state *)
      REPEAT (POP_ASSUM (K ALL_TAC)) >>

      (* goal is now a birs_env_vars_are_initialised predicate *)
      (* --- first the variable set *)
      REWRITE_TAC [GSYM varset_thm] >>
      CONV_TAC (RAND_CONV (EVAL THENC holba_convLib.LIST_TO_SET_CONV)) >>
      (* --- then the symbols of the symbolic state *)
      CONV_TAC (LAND_CONV (bir_vars_ofLib.birs_symb_symbols_DIRECT_CONV)) >>
      (* --- symbolic environment is already in standard form and now combine the whole thing *)
      CONV_TAC (bir_vars_ofLib.birs_env_vars_are_initialised_CONV)
    )
);



(*
val bpre = ``^bir_incr_pre pre_x10``;
val bsys1 = sys1;
val bpost = ``^bir_incr_post pre_x10``;
val bsys2 = sys2;
(snd o dest_eq o concl o EVAL) bpre;
bsymbstate_bconcpred_bsymbval bsys1 bpre;
bsymbstate_pcond bsys1;
bsymbstate_pcond bsys2;
(snd o dest_eq o concl o EVAL) bpost;
bsymbstate_bconcpred_bsymbval bsys2 bpost;
*)
fun bsymbstate_bconcpred_bsymbval bsys bcond =
  let
    val birs_eval_thm = 
      (computeLib.RESTR_EVAL_CONV [birs_eval_exp_tm, birs_gen_env_tm] THENC
       REWRITE_CONV [GSYM birs_gen_env_thm, GSYM birs_gen_env_NULL_thm] THENC
       GEN_match_conv is_birs_eval_exp birs_stepLib.birs_eval_exp_CONV THENC
       EVAL)
      ``FST (THE (birs_eval_exp ^bcond ((^bsys).bsst_environ)))``;
    val birs_eval_res = (snd o dest_eq o concl) birs_eval_thm;
    val _ = if not (pairSyntax.is_fst birs_eval_res) then () else raise mk_HOL_ERR "symbexec_transfer_lib" "bsymbstate_bconcpred_bsymbval" "could not finish symbolic evaluation";
  in
    birs_eval_res
  end;
fun bsymbstate_pcond bsys =
  (snd o dest_eq o concl o SIMP_CONV (std_ss++birs_state_ss) [birs_state_init_pre_GEN_def]) ``(^bsys).bsst_pcond``;
(*
forall valuations:
(
  apply initial symbolic state to bpre to get symbolic expression (i.e., rename variables in bpre to symbols) /\
  path condition of initial symbolic state /\
  path condition of final symbolic state /\
  (add all abbreviations here)
)
==>
(
  apply final symbolic state to bpost to get symbolic expression
)
*)
fun gen_birs_smt_implcond bsys1 bpre bsys2 bpost =
  let
    val bspre          = bsymbstate_bconcpred_bsymbval bsys1 bpre;
    val bsys1_pathcond = bsymbstate_pcond bsys1;
    val bsys2_pathcond = bsymbstate_pcond bsys2;
    val bspost         = bsymbstate_bconcpred_bsymbval bsys2 bpost;
  in
    bslSyntax.bor (bslSyntax.bnot (bslSyntax.bandl [bspre, bsys1_pathcond, bsys2_pathcond]), bspost)
  end;

(*
symbs in H' are the query variables here;
alternative for better performance - use abbreviations for symbols to avoid blowup of symbolic expression;
*)
val birs_strongpostcond_impl_pat_tm = ``
  sys1 = SYS1 ==>
  sys2 = SYS2 ==>
  birs_symb_matchstate sys1 H bs1 ==>
  bir_eval_exp BPRE  bs1.bst_environ = SOME bir_val_true ==>
  birs_symb_matchstate sys2 H bs2 ==>
  bir_eval_exp BPOST bs2.bst_environ = SOME bir_val_true``;
fun birs_strongpostcond_impl_TAC (assum_list, goal) =
  let
    val _ = if List.null assum_list then () else raise mk_HOL_ERR "symbexec_transfer_lib" "birs_strongpostcond_impl_TAC" "assumption list not empty";
    val tm_subst =
      fst (match_term birs_strongpostcond_impl_pat_tm goal)
      handle _ => raise mk_HOL_ERR "symbexec_transfer_lib" "birs_strongpostcond_impl_TAC" "wrong goal shape";
    val bsys1 = subst tm_subst ``SYS1:birs_state_t``;
    val bsys2 = subst tm_subst ``SYS2:birs_state_t``;
    val bpre  = subst tm_subst ``BPRE:bir_exp_t``;
    val bpost = subst tm_subst ``BPOST:bir_exp_t``;
    val bs_imp_tm = gen_birs_smt_implcond bsys1 bpre bsys2 bpost;

    val imp_is_taut = bir_smtLib.bir_smt_check_taut false bs_imp_tm;
    val oracle_thm = 
      if imp_is_taut then
        mk_oracle_thm "BIRS_TRANSF_LIB_Z3" ([], goal)
      else
        raise mk_HOL_ERR "symbexec_transfer_lib" "birs_strongpostcond_impl_TAC" "could not prove tautology";
  in
    ([], K oracle_thm)
  end;

end (* local *)

end (* structure *)

