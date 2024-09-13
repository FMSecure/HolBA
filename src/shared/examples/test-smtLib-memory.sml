open HolKernel Parse boolLib bossLib;

open bir_immSyntax;

open bslSyntax;

open bir_smtLib;

val _ = Parse.current_backend := PPBackEnd.vt100_terminal;
val _ = Globals.show_types := true;
val _ = PolyML.print_depth 1;

(* TODO: then try what happens when the export works differently: prelude/direct-concat-extract/extract-multiple-asserts-abbreviations *)

(*
val ad_sz = 64;
val val_sz = 32;
*)
fun gen_testcase ad_sz val_sz =
 let
  val align_val = (val_sz div 8) - 1;
  val align_val_tm = wordsSyntax.mk_wordii (align_val, ad_sz);
  val ad_sz_bit_tm = bir_immtype_t_of_size ad_sz;
  val ad_sz_imm_tm = bir_imm_of_size ad_sz;
  val val_sz_bit_tm = bir_immtype_t_of_size val_sz;
  val val_sz_imm_tm = bir_imm_of_size val_sz;

  val end_tm = ``BEnd_LittleEndian``;
  
  val MEM_tm = ``(BVar "sy_MEM8" (BType_Mem ^ad_sz_bit_tm Bit8))``;
  val MEM_e_tm = ``(BExp_Den ^MEM_tm)``;
  val ad0_deref_tm = ``BExp_Const (^val_sz_imm_tm pre_x10_deref)``;
  val ad1_deref_tm = ``BExp_Const (^val_sz_imm_tm pre_x11_deref)``;
  val ad0_tm = ``BExp_Den (BVar "sy_x10" (BType_Imm ^ad_sz_bit_tm))``;
  val ad1_tm = ``BExp_Den (BVar "sy_x11" (BType_Imm ^ad_sz_bit_tm))``;
  val conds_tms = [``BExp_BinPred BIExp_Equal
                             (BExp_BinExp BIExp_And
                                (^ad0_tm)
                                (BExp_Const (^ad_sz_imm_tm ^align_val_tm)))
                             (BExp_Const (^ad_sz_imm_tm 0w))``,
             ``BExp_BinPred BIExp_Equal
                                (BExp_BinExp BIExp_And
                                   (^ad1_tm)
                                   (BExp_Const (^ad_sz_imm_tm ^align_val_tm)))
                                (BExp_Const (^ad_sz_imm_tm 0w))``,
             ``BExp_BinPred BIExp_Equal
                                   (BExp_Load
                                      (^MEM_e_tm)
                                      (^ad0_tm)
                                      ^end_tm ^val_sz_bit_tm)
                                   (^ad0_deref_tm)``,
             ``BExp_BinPred BIExp_Equal
                                      (BExp_Load
                                         (^MEM_e_tm)
                                         (^ad1_tm)
                                         ^end_tm ^val_sz_bit_tm)
                                      (^ad1_deref_tm)``];

  val conds = [];
  val vars = Redblackset.empty smtlib_vars_compare;

  val (conds,vars) = foldr (fn (cond_tm,(conds,vars)) =>
    let
      val (conds, vars, str) = bexp_to_smtlib conds vars cond_tm;
    in
      (str::conds, vars)
    end) (conds,vars) conds_tms;

  (*
  (assert (= (bvand ad0 (_ bv1 64)) (_ bv0 64)))
  (assert (= (bvand ad1 (_ bv1 64)) (_ bv0 64)))
  (assert (= (loadfun_64_8_16 M ad0) ad0_deref))
  (assert (= (loadfun_64_8_16 M ad1) ad1_deref))
  *)

  val M_tm = ``BExp_Store
                        (BExp_Store
                           (^MEM_e_tm)
                           (^ad0_tm)
                           ^end_tm
                           (^ad1_deref_tm))
                        (^ad1_tm)
                        ^end_tm
                        (^ad0_deref_tm)``;

  val query_tm = bnot (band (beq (bload M_tm ad0_tm end_tm val_sz_bit_tm, ad1_deref_tm),
                             beq (bload M_tm ad1_tm end_tm val_sz_bit_tm, ad0_deref_tm)));

  val (conds, vars, str) = bexp_to_smtlib conds vars query_tm;

  (*
  (assert (not (and 
    (= (loadfun_64_8_16 (storefun_64_8_16 (storefun_64_8_16 M ad0 ad1_deref) ad1 ad0_deref) ad0) ad1_deref)
    (= (loadfun_64_8_16 (storefun_64_8_16 (storefun_64_8_16 M ad0 ad1_deref) ad1 ad0_deref) ad1) ad0_deref))))
  *)

  val query_conds = [str]@conds;
 in
  ("swap case ad=" ^ (Int.toString ad_sz) ^ " val=" ^ (Int.toString val_sz), vars, query_conds, BirSmtUnsat)
 end;

val z3_binaries = [NONE];

(*
val z3_binaries =
 [SOME "/home/andreas/data/hol/HolBA_opt/z3-4.8.4/bin/z3",
  SOME "/home/andreas/data/hol/HolBA_opt/z3-4.8.17/bin/z3",
  SOME "/home/andreas/data/hol/HolBA_opt/z3-4.12.2/bin/z3",
  SOME "/home/andreas/data/hol/HolBA_opt/z3-4.13.0/bin/z3"];
*)

val test_cases =
  [gen_testcase 32 8,
   (*gen_testcase 32 16,*)
   gen_testcase 32 32,
   gen_testcase 32 64,
   gen_testcase 64 8,
   (*gen_testcase 64 16,*)
   gen_testcase 64 32,
   gen_testcase 64 64];

fun z3bin_to_id NONE = "default"
  | z3bin_to_id (SOME x) = ((fn l => List.nth (l, 2)) o rev o String.tokens (fn x => x = #"/")) x;

fun combine_test_cases test_cases z3bin_o =
  List.map (fn (name, vars, query_conds, expected) =>
     ((z3bin_to_id z3bin_o) ^ ": " ^ name, z3bin_o, vars, query_conds, expected)) test_cases;
val test_cases = List.concat (List.map (combine_test_cases test_cases) z3_binaries);

val _ = print "Testing with z3\n";

val timeout_o = SOME 4000;

(*
val z3bin_o = NONE : string option;
val (name, vars, query_conds, expected) = gen_testcase 64 64;

val (name, z3bin_o, vars, query_conds, expected) = hd test_cases;
val test_cases = tl test_cases;
*)

val results = List.map (fn (name, z3bin_o, vars, query_conds, expected) =>
    let
      val _ = print ("\n\n=============== >>> RUNNING TEST CASE '" ^ name ^ "'\n");

      (* check with timeout, because these test cases might cause excessive runtime or non-termination *)
      val result = querysmt_gen timeout_o z3bin_o vars query_conds;
      val res = result = expected;

      val _ = if res then print ("=============== >>> SUCCESS\n") else (
            print ("=============== >>> TEST CASE FAILED: '" ^ name ^ "'\n");
            print ("have: \n");
            PolyML.print result;
            print ("expected: \n");
            PolyML.print expected;
	    ());
    in res end
  ) test_cases;

val _ = if all I results then () else
  raise Fail "at least one test case failed";
