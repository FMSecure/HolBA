structure birs_composeLib =
struct

local

  open HolKernel Parse boolLib bossLib;


  (* error handling *)
  val libname = "bir_symb_composeLib"
  val ERR = Feedback.mk_HOL_ERR libname
  val wrap_exn = Feedback.wrap_exn libname

(*
open symb_recordTheory;
open symb_prop_transferTheory;
open bir_symbTheory;

open bir_symb_sound_coreTheory;
open HolBACoreSimps;
open symb_interpretTheory;
open pred_setTheory;
*)
  open bir_vars_ofLib;

  open birsSyntax;
  open birs_auxTheory;
  val birs_state_ss = rewrites (type_rws ``:birs_state_t``);

in

(* TODO: this should go to auxTheory *)
val simplerewrite_thm = prove(``
!s t g.
g INTER (s DIFF t) =
s INTER (g DIFF t)
``,
(*REWRITE_RULE [Once pred_setTheory.INTER_COMM] pred_setTheory.DIFF_INTER*)
METIS_TAC [pred_setTheory.INTER_COMM, pred_setTheory.DIFF_INTER]
);

fun freevarset_CONV tm =
(
  (*REWRITE_CONV [Once (simplerewrite_thm)] THENC*) (* TODO: was this a good thing for composition when there are many unused/unchanged symbols around? *)

  (RAND_CONV (
   aux_setLib.DIFF_CONV EVAL
  )) THENC

  (* then INTER *)
  aux_setLib.INTER_INSERT_CONV
) tm;

(*
fun freevarset_CONV tm =
(
  REWRITE_CONV [Once (prove(``
!s t g.
g INTER (s DIFF t) =
s INTER (g DIFF t)
``,
(*REWRITE_RULE [Once pred_setTheory.INTER_COMM] pred_setTheory.DIFF_INTER*)
METIS_TAC [pred_setTheory.INTER_COMM, pred_setTheory.DIFF_INTER]
))] THENC

  (* DIFF first *)
(*
  RATOR_CONV (RAND_CONV (SIMP_CONV (std_ss++HolBACoreSimps.holBACore_ss++string_ss) [pred_setTheory.INSERT_INTER, pred_setTheory.INTER_EMPTY])) THENC
*)
 (* RATOR_CONV (RAND_CONV (INTER_INSERT_CONV)) THENC*)
  (RAND_CONV (
(*
   (fn tm => prove (``^tm = EMPTY``, cheat))
*)
   aux_setLib.DIFF_INSERT_CONV
)) THENC
(*
(fn tm => (if false then print ".\n" else print_term tm; print "aa\n\n"; REFL tm)) THENC
*)

  

  (* then INTER *)
  aux_setLib.INTER_INSERT_CONV
) tm;

(* EVAL tm *)
*)

(* first prepare the SEQ rule for prog *)
fun birs_rule_SEQ_prog_fun bprog_tm =
    (ISPEC (bprog_tm) birs_rulesTheory.birs_rule_SEQ_gen_thm, bprog_tm);

(* symbol freedom helper function *)
(* has to solve this ((birs_symb_symbols bsys_A) INTER (birs_freesymbs bsys_B bPi_B) = EMPTY) *)
(* TODO: probably should remove the parameter freesymbols_B_thm_o, because obsolete since we have a special STEP_SEQ rule *)
val speedcheat = ref false;
fun birs_rule_SEQ_free_symbols_fun freesymbols_tm freesymbols_B_thm_o =
  let

    val freesymbols_thm = prove(freesymbols_tm,
      (if !speedcheat then cheat else ALL_TAC) >> 
      (case freesymbols_B_thm_o of
          NONE => ALL_TAC
        | SOME freesymbols_B_thm => (print_thm freesymbols_B_thm; raise ERR "" ""; REWRITE_TAC [freesymbols_B_thm, pred_setTheory.INTER_EMPTY])) >>

      CONV_TAC (LAND_CONV (LAND_CONV (birs_symb_symbols_DIRECT_CONV))) >>
      CONV_TAC (LAND_CONV (RAND_CONV (birs_freesymbs_DIRECT_CONV))) >>
      (* now have A INTER (B DIFF C) = EMPTY*)

(*
      (fn (al,g) => (print_term g; ([(al,g)], fn ([t]) => t))) >>
*)
      (fn (al,g) => (print "starting to proof free symbols\n"; ([(al,g)], fn ([t]) => t))) >>

      CONV_TAC (RATOR_CONV (RAND_CONV (freevarset_CONV))) >>
      (fn (al,g) => (print "finished to proof free symbols operation\n"; ([(al,g)], fn ([t]) => t))) >>

      REWRITE_TAC [pred_setTheory.EMPTY_SUBSET]
      >> (fn (al,g) => (print "finished to proof free symbols\n"; ([(al,g)], fn ([t]) => t)))

(*
      EVAL_TAC (* TODO: speed this up... *)
*)

(*
      FULL_SIMP_TAC (std_ss) [pred_setTheory.IMAGE_INSERT, pred_setTheory.IMAGE_EMPTY] >>
      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_symb_symbols_thm] >>

      CONV_TAC (conv) >>
      REPEAT (
        CHANGED_TAC ( fn xyz =>
            REWRITE_TAC [Once (prove(``!x. (IMAGE bir_vars_of_exp x) = I (IMAGE bir_vars_of_exp x)``, REWRITE_TAC [combinTheory.I_THM]))]
            xyz
        ) >>
        CONV_TAC (GEN_match_conv combinSyntax.is_I (RAND_CONV birs_exps_of_senv_CONV))
      ) >>

      EVAL_TAC
*)
(*
      CONV_TAC (conv)
      CONV_TAC (fn tm => (print_term tm; REFL tm))
      CONV_TAC (DEPTH_CONV (PAT_CONV ``\A. (I:((bir_var_t->bool)->bool)->((bir_var_t->bool)->bool)) A`` (fn tm => (print_term tm; raise Fail "abcdE!!!"))))



(combinSyntax.is_I o snd o dest_comb) tm





      CONV_TAC (ONCE_DEPTH_CONV (PAT_CONV ``\A. IMAGE bir_vars_of_exp A`` (birs_exps_of_senv_CONV)))


FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) []
      EVAL_TAC

      CONV_TAC (PAT_CONV ``\A. (A DIFF C)`` (conv))





      FULL_SIMP_TAC (std_ss++birs_state_ss) [birs_exps_of_senv_thm, birs_exps_of_senv_COMP_thm] >>

      EVAL_TAC
    (*
      FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) [pred_setTheory.GSPECIFICATION]
    *)
*)
    );
  in
    freesymbols_thm
  end;

(*
val step_A_thm = single_step_A_thm;
val step_B_thm = single_step_B_thm;
val freesymbols_B_thm_o = SOME (prove(T, cheat));
*)
fun birs_rule_SEQ_fun (birs_rule_SEQ_thm, bprog_tm) step_A_thm step_B_thm freesymbols_B_thm_o =
  let
    val (bprog_A_tm,_) = (dest_birs_symb_exec o concl) step_A_thm;
    val (bprog_B_tm,_) = (dest_birs_symb_exec o concl) step_B_thm;
    val _ = if identical bprog_tm bprog_A_tm andalso identical bprog_tm bprog_B_tm then () else
            raise Fail "birs_rule_SEQ_fun:: the programs have to match";

    val prep_thm =
      HO_MATCH_MP (HO_MATCH_MP birs_rule_SEQ_thm step_A_thm) step_B_thm;

    val freesymbols_tm = (fst o dest_imp o concl) prep_thm;
    val freesymbols_thm = birs_rule_SEQ_free_symbols_fun freesymbols_tm freesymbols_B_thm_o;
    val _ = print "finished to proof free symbols altogether\n";

    val bprog_composed_thm =
           (MATCH_MP
              prep_thm
              freesymbols_thm);
    val _ = print "composed\n";

    (* tidy up set operations to not accumulate (in both, post state set and label set) *)
    fun Pi_CONV conv tm =
      RAND_CONV (RAND_CONV (conv handle e => (print "\n\nPi_CONV failed\n\n"; raise e))) tm;
    fun L_CONV conv tm =
      RAND_CONV (LAND_CONV (conv handle e => (print "\n\nL_CONV failed\n\n"; raise e))) tm;

    val bprog_Pi_fixed_thm = CONV_RULE (RAND_CONV (Pi_CONV aux_setLib.birs_state_DIFF_UNION_CONV)) bprog_composed_thm;

    val bprog_L_fixed_thm  = CONV_RULE (RAND_CONV (L_CONV (
      EVAL
      (* TODO: this has to be fixed as list of address spaces that can be merged and so on...
         (can we make this only involve the block label part, not the block index?) *)
        ))) bprog_Pi_fixed_thm;

    val _ = if symb_sound_struct_is_normform (concl bprog_L_fixed_thm) then () else
            (print_term (concl bprog_L_fixed_thm);
             raise ERR "birs_rule_SEQ_fun" "something is not right, the produced theorem is not evaluated enough");
  in
    bprog_L_fixed_thm
  end;


end (* local *)

end (* struct *)
