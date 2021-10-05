
open HolKernel Parse boolLib bossLib;

open bir_inst_liftingLib;
open bir_inst_liftingLibTypes;
open bir_inst_liftingHelpersLib;
open gcc_supportLib;
open PPBackEnd Parse;

open bir_programSyntax;

open bir_miscLib;

open bslSyntax;


(*
=============================================================================
*)


fun run_naive_hol4_symbexec prog_ =
  let
    open listSyntax;
    open scamv_symb_exec_interfaceLib;

    val timestrref = ref "";
    val timer = timer_start 1;

    val (paths_raw, _) = scamv_run_symb_exec prog_;

    val _ = timer_stop (fn timestr => (timestrref := timestr; print ("naive hol4 symbolic execution took " ^ timestr ^ "\n"))) timer;

    val paths = List.filter (isSome o snd) paths_raw;
  in
    (paths, !timestrref)
  end;


 

fun run_angr_symbexec prog_ =
  let
    val timer = timer_start 1;

    val res = bir_angrLib.do_symb_exec prog_;

    val timestrref = ref "";
    val _ = timer_stop (fn timestr => (timestrref := timestr; print ("angr symbolic execution took " ^ timestr ^ "\n"))) timer;
  in
    (res, !timestrref)
  end;

(*
=============================================================================
*)


val dafilename = "aes-aarch64.da";
val dafilename = "aes-2-aarch64.da";
val dafilename = "aes-vs-aarch64.da";
val dafilename = "retonly-aarch64.da";

(*
=============================================================================
*)

fun lift_prog dafilename =
    let
	val _ = Parse.current_backend := PPBackEnd.vt100_terminal;
	val _ = set_trace "bir_inst_lifting.DEBUG_LEVEL" 2;

	val _ = print_with_style_ [Bold, Underline] ("Lifting " ^ dafilename ^ "\n");

	val (region_map, aes_sections) = read_disassembly_file_regions dafilename;

	val (thm_arm8, errors) = bmil_arm8.bir_lift_prog_gen ((Arbnum.fromInt 0), (Arbnum.fromInt 0x1000000)) aes_sections;

	val prog = (snd o dest_comb o concl) thm_arm8;


	val _ = print "\nLifting done.\n\n";
    in
	prog
    end;

(* val prog = lift_prog dafilename; *)

(*
=============================================================================
*)

(*
val prog_raw = “BirProgram
      [<|bb_label :=
           BL_Address_HC (Imm64 (0w :word64)) "D10043FF (sub sp, sp, #0x10)";
         bb_statements :=
           [(BStmt_Assign (BVar "SP_EL0" (BType_Imm Bit64))
               (BExp_BinExp BIExp_Minus
                  (BExp_Den (BVar "SP_EL0" (BType_Imm Bit64)))
                  (BExp_Const (Imm64 (16w :word64)))))];
         bb_last_statement :=
           BStmt_Halt (BExp_Const (Imm64 4w))|>]
:bir_val_t bir_program_t”;

  val mem_bounds =
      let
        open experimentsLib;
        open wordsSyntax;
        val (mem_base, mem_len) = embexp_params_memory;
        val mem_end = (Arbnum.- (Arbnum.+ (mem_base, mem_len), Arbnum.fromInt 128));
      in
        pairSyntax.mk_pair
            (mk_wordi (embexp_params_cacheable mem_base, 64),
             mk_wordi (embexp_params_cacheable mem_end, 64))
      end;


val obsmodel_id = "mem_address_pc";
val add_obs = #add_obs (bir_obs_modelLib.get_obs_model obsmodel_id);
val prog = add_obs mem_bounds prog_raw;

val (paths, _) = run_naive_hol4_symbexec prog;
val (res, _) = run_angr_symbexec prog;

*)

(*
scamv_to_angr (hd paths)
*)
fun scamv_to_angr scamv_symbexec_path =
    let
	val (cond_exp, obs_list_opt) = scamv_symbexec_path;
        val obs_list_raw = valOf obs_list_opt
          handle _ => raise Fail "scamv_to_angr: can only handle non-error paths";

        fun scamv_obs_conv (oid, ec, obsexp) =
            (* TODO: fix obslist and HD when using the general obsfun branch *)
            (numSyntax.dest_numeral oid, ec, [obsexp], “HD:bir_val_t list -> bir_val_t”);

        val obs_list = List.map scamv_obs_conv obs_list_raw;

	val r =  {final_pc = "0x0", guards = [cond_exp], jmp_history = [], observations = obs_list};
    in
	bir_angrLib.exec_path r
    end;


(*
val paths_conv = List.map scamv_to_angr paths;

compare_angr_symb_exec_path (hd paths_conv) (hd paths_conv);
compare_angr_symb_exec_path (hd paths_conv) (hd res);
*)
fun z3_is_taut wtm =
  ((HolSmtLib.Z3_ORACLE_PROVE wtm; true)
  handle HOL_ERR e => false);

(*
val wtm1 = “(a:word64) + (b:word64) + 3w + 2w = (b:word64) + 5w + (a:word64)”;
val wtm2 = “(a:word64) + (b:word64) + 3w + 2w = (b:word64) + 6w + (a:word64)”;
z3_is_taut wtm1;
z3_is_taut wtm2;

----

val bexp_l  = bplusl [bden (bvarimm64 "a"), bden (bvarimm64 "b"), bconst64 3, bconst64 2];
val bexp_r1 = bplusl [bden (bvarimm64 "b"), bconst64 5, bden (bvarimm64 "a")];
val bexp_r2 = bplusl [bden (bvarimm64 "b"), bconst64 6, bden (bvarimm64 "a")];

birexp_semantics_eq bexp_l bexp_r1
birexp_semantics_eq bexp_l bexp_r2

----

val guards_l  = [beq (bexp_l,  bconst64 42)];
val guards_r1 = [beq (bexp_r1, bconst64 42)];
val guards_r2 = [beq (bexp_r2, bconst64 42)];

compare_angr_guards guards_l guards_r1;
compare_angr_guards guards_l guards_r2;
*)
fun birexp_semantics_eq be1 be2 =
  let
    val eq_bexp = beq (be1, be2);
    val eq_wtm = bir_exp_to_wordsLib.bir2bool eq_bexp;
  in
    z3_is_taut eq_wtm
  end;
fun compare_angr_guards guards1 guards2 =
  let
    val pcond1_bexp = bandl guards1;
    val pcond2_bexp = bandl guards2;
  in
    birexp_semantics_eq pcond1_bexp pcond2_bexp
  end;

fun zip [] _ = []
  | zip _ [] = []
  | zip (x::xs) (y::ys) = (x,y) :: zip xs ys;
fun compare_angr_obspair
  ((oid1, ocond1, obsl1, obsf1),
   (oid2, ocond2, obsl2, obsf2)) =
  Arbnum.compare (oid1, oid2) = EQUAL andalso
  birexp_semantics_eq ocond1 ocond2 andalso
  length obsl1 = length obsl2 andalso
  List.all (fn (x,y) => birexp_semantics_eq x y) (zip obsl1 obsl2) andalso
  identical obsf1 obsf2;
fun compare_angr_observations l1 l2 =
  length l1 = length l2 andalso
  List.all compare_angr_obspair (zip l1 l2);





fun compare_angr_symb_exec_path
  (bir_angrLib.exec_path {guards = guards1, observations = l1, ...})
  (bir_angrLib.exec_path {guards = guards2, observations = l2, ...}) =
    compare_angr_guards guards1 guards2 andalso
    compare_angr_observations l1 l2;

(*
val bir_angrLib.exec_path pr = (hd paths_conv);
val guards = #guards pr;

bandl [“BExp_Const (Imm1 1w)”, “BExp_Const (Imm1 1w)”,
       “BExp_Const (Imm1 1w)”, “BExp_Const (Imm1 1w)”,
       “BExp_Const (Imm1 1w)”];
bandl guards
*)

(*
- use bslsyntax to make singe bir expressions from pconds
  -- https://github.com/kth-step/HolBA/blob/dev_angrintegr/src/shared/bslSyntax.sig
bandl

- use birexp to word
  -- https://github.com/kth-step/HolBA/blob/dev_angrintegr/src/shared/bir_exp_to_wordsLib.sig
bir2w

- use (snd o dest_eq o concl o EVAL) “^obsf ^w” with obsfun

- send to smt solver for actual comparison
  -- https://github.com/kth-step/HolBA/blob/dev_angrintegr/src/shared/Z3_SAT_modelLib.sig
Z3_GET_SAT_MODEL
  -- https://github.com/kth-step/HolBA/blob/dev_angrintegr/src/tools/scamv/symbexec/bir_symb_masterLib.sml
pdecide
*)



fun every_exists P l1 l2 =
  List.all (fn x1 => List.exists (fn x2 => P x1 x2) l2) l1;

fun compare_angr_symb_exec paths1 paths2 =
  every_exists compare_angr_symb_exec_path paths1 paths2 andalso
  every_exists compare_angr_symb_exec_path paths2 paths1;

(*
val paths_conv = List.map scamv_to_angr paths;

compare_angr_symb_exec paths_conv paths_conv;
compare_angr_symb_exec paths_conv res;
*)



(*
=============================================================================
*)


fun main_loop 0 = ()
  |  main_loop n =
     let
	 open bir_prog_genLib;

	 val prog = if true then
			(* Prefetching *)
		     let	 
			 val gen_prefetch = prog_gen_store_prefetch_stride 3;
			 val prog = gen_prefetch ();
			 val (prog_id, lifted_prog) = prog;
		     in
			 lifted_prog
		     end
		    else
			(* Spectre *)	
		     let		 
			 (* val (prog_id, lifted_prog) = prog_gen_store_rand "" 2 (); *)
			 val (prog_id, lifted_prog) = prog_gen_store_a_la_qc  "spectre_v1" 5 ();
			 val prog = lifted_prog;
		     in
			 prog
		     end;
	     
	 val prog = (snd o dest_eq o concl o EVAL) prog;
	 val _ = print "\nInput prog prepared.\n\n";

         val obsmodel_id = "mem_address_pc";
         local
           val mem_bounds =
             let
               open experimentsLib;
               open wordsSyntax;
               val (mem_base, mem_len) = embexp_params_memory;
               val mem_end = (Arbnum.- (Arbnum.+ (mem_base, mem_len), Arbnum.fromInt 128));
             in
               pairSyntax.mk_pair
                   (mk_wordi (embexp_params_cacheable mem_base, 64),
                    mk_wordi (embexp_params_cacheable mem_end, 64))
             end;
           val add_obs = #add_obs (bir_obs_modelLib.get_obs_model obsmodel_id);
         in
           val prog = add_obs mem_bounds prog;
         end;
	 val _ = print ("\nObsmodel applied \"" ^ obsmodel_id ^ "\".\n\n");
	     
	 val _ = print "\nNow symbexecing.\n\n";

	 val (paths, _) = run_naive_hol4_symbexec prog;

	 val (res, _) = run_angr_symbexec prog;

         val paths_conv = List.map scamv_to_angr paths;
         val eq_result = compare_angr_symb_exec paths_conv res;
         val _ =
           if eq_result then
             print "yippie!!!\n"
           else
             print "oh noo!!!\n";

	 val _ = print "\nDone symbexecing.\n\n";
     in
	 main_loop (n-1)
     end;
    
(*
=============================================================================
*)

val _ = main_loop 2;
