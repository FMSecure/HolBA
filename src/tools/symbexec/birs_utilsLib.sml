structure birs_utilsLib =
struct

local

  open HolKernel Parse boolLib bossLib;

  open birsSyntax;

  (* error handling *)
  val libname = "birs_utilsLib"
  val ERR = Feedback.mk_HOL_ERR libname
  val wrap_exn = Feedback.wrap_exn libname

in (* local *)

  (* TODO: move the generic list functions somewhere else *)
  fun list_distinct _ [] = true
    | list_distinct eq_fun (x::xs) =
        if all (fn y => (not o eq_fun) (x, y)) xs then list_distinct eq_fun xs else false;

  fun list_mk_distinct_ _ [] acc = List.rev acc
    | list_mk_distinct_ eq_fun (x::xs) acc =
        list_mk_distinct_ eq_fun (List.filter (fn y => not (eq_fun (x, y))) xs) (x::acc);

  fun list_mk_distinct eq_fun l =
      list_mk_distinct_ eq_fun l [];

  (* the following two functions are from test-z3-wrapper.sml *)
  fun list_inclusion eq_fun l1 l2 =
    foldl (fn (x, acc) => acc andalso (exists (fn y => eq_fun (x, y)) l2)) true l1;

  local
    (* better than Portable.list_eq, because not order sensitive *)
    fun mutual_list_inclusion eq_fun l1 l2 =
      list_inclusion eq_fun l1 l2 andalso
      length l1 = length l2;
  in
    val list_eq_contents =
      mutual_list_inclusion;
  end

  fun list_in eq_fun x l =
    List.exists (fn y => eq_fun (x,y)) l;

  (* find the common elements of two lists *)
  fun list_commons eq_fun l1 l2 =
    List.foldl (fn (x,acc) => if list_in eq_fun x l2 then x::acc else acc) [] l1;

  fun list_minus eq_fun l1 l2 =
    List.filter (fn x => not (list_in eq_fun x l2)) l1;

  val gen_eq = (fn (x,y) => x = y);
  val term_id_eq = (fn (x,y) => identical x y);

(* ---------------------------------------------------------------------------------------- *)

  (* get all mapped variable names *)
  fun birs_env_varnames birs_tm =
    let
      val _ = birs_check_state_norm ("birs_env_varnames", "") birs_tm;

      val env = dest_birs_state_env birs_tm;
      val mappings = get_env_mappings env;
      val varname_tms = List.map fst mappings;
      val varnames = List.map stringSyntax.fromHOLstring varname_tms;
      (* now that we have the mappings, also check that varnames is distinct *)
      val _ = if list_distinct gen_eq varnames then () else
              raise ERR "birs_env_varnames" "state has one variable mapped twice";
    in
      varnames
    end;

(* ---------------------------------------------------------------------------------------- *)

  local
    open pred_setSyntax;
    open pred_setTheory;
    val rotate_first_INSERTs_thm = prove(``
      !x1 x2 xs.
      (x1 INSERT x2 INSERT xs) = (x2 INSERT x1 INSERT xs)
    ``,
      fs [EXTENSION] >>
      metis_tac []
    );
    fun is_two_INSERTs tm = (is_insert tm) andalso ((is_insert o snd o dest_insert) tm);
  in
    fun rotate_two_INSERTs_conv tm =
      let
        val _ = if is_two_INSERTs tm then () else
          raise ERR "rotate_two_INSERTs_conv" "need to be a term made up of two inserts";
        val (x1_tm, x2xs_tm) = dest_insert tm;
        val (x2_tm, xs_tm) = dest_insert x2xs_tm;
        val inst_thm = ISPECL [x1_tm, x2_tm, xs_tm] rotate_first_INSERTs_thm;
      in
        inst_thm
      end;

    fun rotate_INSERTs_conv tm =
      (if not (is_two_INSERTs tm) then REFL else
        (rotate_two_INSERTs_conv THENC
        RAND_CONV rotate_INSERTs_conv)) tm;
  end

(* ---------------------------------------------------------------------------------------- *)

  fun check_imp_tm imp_tm =
    if not (is_birs_exp_imp imp_tm) then raise ERR "check_imp_tm" "term needs to be birs_exp_imp" else
    let
      val (pred1_tm, pred2_tm) = dest_birs_exp_imp imp_tm;
      val imp_bexp_tm = bslSyntax.bor (bslSyntax.bnot pred1_tm, pred2_tm);
      val imp_is_taut = bir_smtLib.bir_smt_check_taut false imp_bexp_tm;
    in
      if imp_is_taut then
        SOME (mk_oracle_thm "BIRS_SIMP_LIB_Z3" ([], imp_tm))
      else
        NONE
    end;
  val check_imp_tm = aux_moveawayLib.wrap_cache_result Term.compare check_imp_tm;

  fun check_pcondinf_tm pcondinf_tm =
    if not (is_birs_pcondinf pcondinf_tm) then raise ERR "check_pcondinf_tm" "term needs to be birs_pcondinf" else
    let
      val pcond_tm = dest_birs_pcondinf pcondinf_tm;
      val pcond_is_contr = bir_smtLib.bir_smt_check_unsat false pcond_tm;
    in
      if pcond_is_contr then
        SOME (mk_oracle_thm "BIRS_CONTR_Z3" ([], pcondinf_tm))
      else
        NONE
    end;
  val check_pcondinf_tm = aux_moveawayLib.wrap_cache_result Term.compare check_pcondinf_tm;

  local
    fun try_prove_assumption conv assmpt =
      let
          val assmpt_thm = conv assmpt;

          val assmpt_new = (snd o dest_eq o concl) assmpt_thm;

          (* raise exception when the assumption turns out to be false *)
          val _ = if not (identical assmpt_new F) then () else
                  raise ERR "try_prove_assumption" "assumption does not hold";

          val _ = if identical assmpt_new T then () else
                  raise ERR "try_prove_assumption" ("failed to fix the assumption: " ^ (term_to_string assmpt));
      in
        if identical assmpt_new T then
          SOME (EQ_MP (GSYM assmpt_thm) TRUTH)
        else
          NONE
      end
      handle _ => NONE;
    val try_prove_assumption = fn conv => aux_moveawayLib.wrap_cache_result Term.compare (try_prove_assumption conv);

    fun try_prove_assumptions remove_all conv NONE = NONE
      | try_prove_assumptions remove_all conv (SOME t) =
      if (not o is_imp o concl) t then
        SOME t
      else
        let
          val assmpt = (fst o dest_imp o concl) t;
          val assmpt_thm_o = try_prove_assumption conv assmpt;
        in
          case assmpt_thm_o of
            NONE => if remove_all then NONE else SOME t
          | SOME assmpt_thm =>
              try_prove_assumptions
                remove_all
                conv
                (SOME (MP t assmpt_thm))
        end;
  in
    fun prove_assumptions remove_all conv thm = try_prove_assumptions remove_all conv (SOME thm);
  end

(* ---------------------------------------------------------------------------------------- *)

  val birs_exp_imp_DROP_R_thm = prove(``
    !be1 be2.
    birs_exp_imp (BExp_BinExp BIExp_And be1 be2) be1
  ``,
    (* maybe only true for expressions of type Bit1 *)
    cheat
  );
  val birs_exp_imp_DROP_L_thm = prove(``
    !be1 be2.
    birs_exp_imp (BExp_BinExp BIExp_And be1 be2) be2
  ``,
    (* maybe only true for expressions of type Bit1 *)
    cheat
  );

  fun is_DROP_R_imp imp_tm =
    (SOME (UNCHANGED_CONV (REWRITE_CONV [birs_exp_imp_DROP_R_thm]) imp_tm)
            handle _ => NONE);

  fun is_DROP_L_imp imp_tm =
    (SOME (UNCHANGED_CONV (REWRITE_CONV [birs_exp_imp_DROP_L_thm]) imp_tm)
            handle _ => NONE);

  fun is_conjunct_inclusion_imp imp_tm =
    let
      val (pcond1, pcond2) = dest_birs_exp_imp imp_tm;
      val pcond1l = dest_bandl pcond1;
      val pcond2l = dest_bandl pcond2;

      (* find the common conjuncts by greedily collecting what is identical in both *)
      val imp_is_ok = list_inclusion term_id_eq pcond2l pcond1l;
    in
      if imp_is_ok then
        SOME (mk_oracle_thm "BIRS_CONJ_INCL_IMP" ([], imp_tm))
      else
        NONE
    end;

  (* general path condition weakening with z3 (to throw away path condition conjuncts (to remove branch path condition conjuncts)) *)
  fun birs_Pi_first_pcond_RULE pcond_new thm =
    let
      val _ = birs_check_norm_thm ("birs_Pi_first_pcond_RULE", "") thm;

      val (p_tm, tri_tm) = (dest_birs_symb_exec o concl) thm;
      val (sys_tm,L_tm,Pi_old_tm) = dest_sysLPi tri_tm;
      val (Pi_sys_old_tm, Pi_rest_tm) = pred_setSyntax.dest_insert Pi_old_tm;

      val (pc, env, status, pcond_old) = dest_birs_state Pi_sys_old_tm;
      val Pi_sys_new_tm = mk_birs_state (pc, env, status, pcond_new);
      val Pi_new_tm = pred_setSyntax.mk_insert (Pi_sys_new_tm, Pi_rest_tm);

      val imp_tm = mk_birs_exp_imp (pcond_old, pcond_new);
      (*
      val _ = print_term imp_tm;
      val _ = holba_z3Lib.debug_print := true;
      val _ = print "sending a z3 query\n";
      *)
      val pcond_drop_ok = isSome (is_DROP_R_imp imp_tm) orelse
                          isSome (is_DROP_L_imp imp_tm) orelse
                          isSome (is_conjunct_inclusion_imp imp_tm);
      val pcond_imp_ok = pcond_drop_ok orelse (* TODO: something might be wrong in expression simplification before smtlib-z3 exporter *)
                         isSome (check_imp_tm imp_tm);
      val _ = if pcond_imp_ok then () else
              (print "widening failed, path condition is not weaker\n";
               raise ERR "birs_Pi_first_pcond_RULE" "the supplied path condition is not weaker");
      (* TODO: use the bir implication theorem to justify the new theorem *)
    in
      mk_oracle_thm "BIRS_WIDEN_PCOND" ([], mk_birs_symb_exec (p_tm, mk_sysLPi (sys_tm,L_tm,Pi_new_tm)))
    end;

  fun birs_Pi_first_pcond_drop drop_right thm =
    let
      open bir_expSyntax;
      open bir_exp_immSyntax;
      val Pi_sys_tm = (get_birs_Pi_first o concl) thm;
      val pcond = dest_birs_state_pcond Pi_sys_tm;
      val _ = if is_BExp_BinExp pcond then () else
              raise ERR "birs_Pi_first_pcond_drop" "pcond must be a BinExp";
      val (bop,be1,be2) = dest_BExp_BinExp pcond;
      val _ = if is_BIExp_And bop then () else
              raise ERR "birs_Pi_first_pcond_drop" "pcond must be an And";
      val pcond_new =
        if drop_right then
          be1
        else
          be2;
    in
      birs_Pi_first_pcond_RULE pcond_new thm
    end;

  (* general path condition strengthening with z3 *)
  fun birs_sys_pcond_RULE pcond_new thm =
    let
      val _ = birs_check_norm_thm ("birs_sys_pcond_RULE", "") thm;

      val (p_tm, tri_tm) = (dest_birs_symb_exec o concl) thm;
      val (sys_old_tm,L_tm,Pi_tm) = dest_sysLPi tri_tm;

      val (pc, env, status, pcond_old) = dest_birs_state sys_old_tm;
      val sys_new_tm = mk_birs_state (pc, env, status, pcond_new);

      val imp_tm = mk_birs_exp_imp (pcond_new, pcond_old);
      (*
      val _ = print_term imp_tm;
      val _ = holba_z3Lib.debug_print := true;
      val _ = print "sending a z3 query\n";
      *)
      val pcond_imp_ok = isSome (check_imp_tm imp_tm);
      val _ = if pcond_imp_ok then () else
              (print "narrowing failed, path condition is not stronger\n";
               raise ERR "birs_sys_pcond_RULE" "the supplied path condition is not stronger");
      (* TODO: use the bir implication theorem to justify the new theorem *)
    in
      mk_oracle_thm "BIRS_NARROW_PCOND" ([], mk_birs_symb_exec (p_tm, mk_sysLPi (sys_new_tm,L_tm,Pi_tm)))
    end;

(* ---------------------------------------------------------------------------------------- *)

  local
    val struct_CONV =
      RAND_CONV;
    fun sys_CONV conv =
      LAND_CONV conv;
    fun L_CONV conv =
      RAND_CONV (LAND_CONV conv);
    fun Pi_CONV conv =
      RAND_CONV (RAND_CONV conv);
    val first_CONV =
      LAND_CONV;
    fun second_CONV conv =
      RAND_CONV (first_CONV conv);
  in
    (* apply state transformer to sys *)
    fun birs_sys_CONV conv tm =
      let
        val _ = if is_birs_symb_exec tm then () else
                raise ERR "birs_sys_CONV" "cannot handle term";
      in
        (struct_CONV (sys_CONV conv)) tm
      end;

    (* apply state transformer to L *)
    fun birs_L_CONV conv tm =
      let
        val _ = if is_birs_symb_exec tm then () else
                raise ERR "birs_L_CONV" "cannot handle term";
      in
        struct_CONV (L_CONV conv) tm
      end;

    (* apply state transformer to Pi *)
    fun birs_Pi_CONV conv tm =
      let
        val _ = if is_birs_symb_exec tm then () else
                raise ERR "birs_Pi_CONV" "cannot handle term";
      in
        (struct_CONV (Pi_CONV conv)) tm
      end;

    (* apply state transformer to first state in Pi *)
    (* TODO: should check the number of states in Pi *)
    fun birs_Pi_first_CONV conv =
      birs_Pi_CONV (first_CONV conv);
    fun birs_Pi_second_CONV conv =
      birs_Pi_CONV (second_CONV conv);
  end

  (* modify the environment *)
  fun birs_env_CONV conv birs_tm =
    let
      val _ = birs_check_state_norm ("birs_env_CONV", "") birs_tm;
      val env_new_thm = conv (dest_birs_state_env birs_tm);
    in
      (* better use EQ_MP? *)
      REWRITE_CONV [env_new_thm] birs_tm
    end

  (* move a certain mapping to the top *)
  fun birs_env_var_top_CONV varname birs_tm =
    (* TODO: should use birs_env_CONV *)
    let
      val _ = birs_check_state_norm ("birs_env_var_top_CONV", "") birs_tm;

      val (pc, env, status, pcond) = dest_birs_state birs_tm;
      val (mappings, mappings_ty) = (listSyntax.dest_list o dest_birs_gen_env) env;
      val is_m_for_varname = (fn x => x = varname) o stringSyntax.fromHOLstring o fst o pairSyntax.dest_pair;
      fun get_exp_if m =
        if is_m_for_varname m then SOME m else NONE;
      val m_o = List.foldl (fn (m, acc) => case acc of SOME x => SOME x | NONE => get_exp_if m) NONE mappings;
      val m = valOf m_o handle _ => raise ERR "birs_env_var_top_CONV" "variable name not mapped in bir state";
      val mappings_new = m::(List.filter (not o is_m_for_varname) mappings);

      val env_new = (mk_birs_gen_env o listSyntax.mk_list) (mappings_new, mappings_ty);
      val birs_new_tm = mk_birs_state (pc, env_new, status, pcond);
    in
      mk_oracle_thm "BIRS_ENVVARTOP" ([], mk_eq (birs_tm, birs_new_tm))
    end
    handle _ => raise ERR "birs_env_var_top_CONV" "something uncaught";

(* ---------------------------------------------------------------------------------------- *)

  (* swap the first two states in Pi *)
  fun birs_Pi_rotate_two_RULE thm =
    let
      val _ = birs_check_norm_thm ("birs_Pi_rotate_two_RULE", "") thm;
      val _ = birs_check_min_Pi_thm 2 "birs_Pi_rotate_two_RULE" thm;

      val res_thm = CONV_RULE (birs_Pi_CONV (rotate_two_INSERTs_conv)) thm;
    in
      res_thm
    end;

  fun birs_Pi_rotate_RULE thm =
    let
      val _ = birs_check_norm_thm ("birs_Pi_rotate_RULE", "") thm;
      val _ = birs_check_min_Pi_thm 2 "birs_Pi_rotate_RULE" thm;

      val res_thm = CONV_RULE (birs_Pi_CONV (rotate_INSERTs_conv)) thm;
    in
      res_thm
    end;

  (* goes through all Pi states and applies rule *)
  fun birs_Pi_each_RULE rule thm =
    let
      val len = (get_birs_Pi_length o concl) thm;
      (* iterate through all Pi states (with Pi rotate) and apply rule *)
      val thm_new =
        if len = 0 then
          thm
        else if len = 1 then
          rule thm
        else
          List.foldl (birs_Pi_rotate_RULE o rule o snd) thm (List.tabulate(len, I));
    in
      thm_new
    end;

(* ---------------------------------------------------------------------------------------- *)

  local
    open bir_programSyntax;
    open optionSyntax;
  in
    fun birs_is_stmt_Assign tm = is_some tm andalso (is_BStmtB o dest_some) tm andalso (is_BStmt_Assign o dest_BStmtB o dest_some) tm;
    fun birs_is_exec_branch thm = (get_birs_Pi_length o concl) thm > 1;

    fun birs_cond_RULE c f =
      if c then f else I;
    
    fun birs_if_assign_RULE tm = birs_cond_RULE (birs_is_stmt_Assign tm);
    fun birs_if_branch_RULE f thm = birs_cond_RULE (birs_is_exec_branch thm) f thm;
  end

end (* local *)

end (* struct *)
