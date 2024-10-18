structure birs_strategiesLib =
struct

local

  open HolKernel Parse boolLib bossLib;

  open birsSyntax;
  open birs_utilsLib;

  (* error handling *)
  val libname = "birs_strategiesLib"
  val ERR = Feedback.mk_HOL_ERR libname
  val wrap_exn = Feedback.wrap_exn libname

in (* local *)

  fun not_at_lbls stop_lbls st =
    not (List.exists (identical (dest_birs_state_pc st)) stop_lbls);

  (* TODO: later make the whole post step function a parameter to the symb_analysis function *)
  val birs_simp_select = ref birs_simp_instancesLib.birs_simp_default_riscv;

  fun birs_post_step_riscv_default (birs_rule_SUBST_thm) =
    let
      val timer_symbanalysis = holba_miscLib.timer_start 0;
      val timer_symbanalysis_last = ref (holba_miscLib.timer_start 0);

      open birs_execLib;
      fun birs_post_step_fun (t, (last_pc, last_stmt)) = (
        (fn t => (
        holba_miscLib.timer_stop (fn delta_s => print ("running since " ^ delta_s ^ "\n")) timer_symbanalysis;
        holba_miscLib.timer_stop (fn delta_s => print ("time since last step " ^ delta_s ^ "\n")) (!timer_symbanalysis_last);
        timer_symbanalysis_last := holba_miscLib.timer_start 0;
        (*print_term ((last o pairSyntax.strip_pair o snd o dest_comb o concl) t);*)
        t)) o
        birs_if_assign_RULE last_stmt (birs_rule_SUBST_trysimp_fun birs_rule_SUBST_thm (!birs_simp_select)) o
        birs_rule_tryprune_fun birs_rulesTheory.branch_prune1_spec_thm o
        birs_rule_tryprune_fun birs_rulesTheory.branch_prune2_spec_thm o
        birs_rule_tryjustassert_fun true
      ) t;
    in
      birs_post_step_fun
    end;

  fun birs_post_step_armcm0_default (birs_rule_SUBST_thm) =
    let
      open birs_simp_instancesLib;
      val birs_simp_select = birs_simp_default_armcm0_gen true;
      val birs_simp_select_ifthenelse = birs_simp_default_core_exp_simp;
      open holba_miscLib;

      val timer_symbanalysis = timer_start 0;
      val timer_symbanalysis_last = ref (timer_start 0);
      fun debug_output_RULE t =
         (timer_stop (fn delta_s => print ("running since " ^ delta_s ^ "\n")) timer_symbanalysis;
         timer_stop (fn delta_s => print ("time since last step " ^ delta_s ^ "\n")) (!timer_symbanalysis_last);
         timer_symbanalysis_last := timer_start 0;
         (*print_term ((last o pairSyntax.strip_pair o snd o dest_comb o concl) t);*)
         t);

      open birs_execLib;
      val birs_simp_RULE_gen = birs_rule_SUBST_trysimp_fun birs_rule_SUBST_thm;
      fun birs_simp_RULE last_stmt =
        ((* the ifthenelse simplification for countw assignments before branches, that gets applied after the branch happens and the condition is available in the branchcondition *)
         birs_if_branch_RULE (birs_simp_RULE_gen (birs_simp_select_ifthenelse)) o
         (* the simplification after assignments *)
         birs_if_assign_RULE last_stmt (birs_simp_RULE_gen (birs_simp_select)));
      val birs_prune_RULE =
        (birs_rule_tryprune_fun birs_rulesTheory.branch_prune1_spec_thm o
         birs_rule_tryprune_fun birs_rulesTheory.branch_prune2_spec_thm o
         birs_rule_tryjustassert_fun true);

      fun birs_post_step_fun (t, (last_pc, last_stmt)) = (
         debug_output_RULE o
         (*(apply_if_branch debug_Pi_fun) o*)
         birs_simp_RULE last_stmt o
         birs_prune_RULE
      ) t;
    in
      birs_post_step_fun
    end;

end (* local *)

end (* struct *)
