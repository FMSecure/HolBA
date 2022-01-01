open HolKernel Parse boolLib bossLib;

open bir_angrLib;

val _ = Parse.current_backend := PPBackEnd.vt100_terminal;
val _ = Globals.show_types := false;

val _ = print "Parsing test cases\n";

val angr_exp_testcases = [
  ("<Bool R3_1_16 / 7#16 == 0#16>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_Div (BExp_Den (BVar "R3" (BType_Imm Bit16)))
     (BExp_Const (Imm16 7w))) (BExp_Const (Imm16 0w))``)
  ,("<Bool R0_0_32 /s 0x3#32 != 0x0#32>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_SignedDiv (BExp_Den (BVar "R0" (BType_Imm Bit32)))
	       (BExp_Const (Imm32 3w))) (BExp_Const (Imm32 0w))``)
  ,("<Bool ProcState_C_0_16 ^ 0xa#16 != 0#16>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_Xor (BExp_Den (BVar "ProcState_C" (BType_Imm Bit16)))
     (BExp_Const (Imm16 10w))) (BExp_Const (Imm16 0w))``)
  ,("<Bool 0x3ff#32 * 0x3#32 != R31_0_32>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_Mult (BExp_Const (Imm32 1023w)) (BExp_Const (Imm32 3w)))
  (BExp_Den (BVar "R31" (BType_Imm Bit32)))``)
  ,("<Bool R3_1_8 % (R0_0_8 & 7#8) == 0#8>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_Mod (BExp_Den (BVar "R3" (BType_Imm Bit8)))
     (BExp_BinExp BIExp_And (BExp_Den (BVar "R0" (BType_Imm Bit8)))
        (BExp_Const (Imm8 7w)))) (BExp_Const (Imm8 0w))``)
  ,("<Bool (R27_3_64[7:0] & 7#8) == 0#8>",
   ``BExp_BinPred BIExp_Equal
      (BExp_BinExp BIExp_And
         (BExp_CastMask Bit64 7 0 (BExp_Den (BVar "R27" (BType_Imm Bit64)))
            (THE (bir_immtype_of_size 8))) (BExp_Const (Imm8 7w)))
      (BExp_Const (Imm8 0w))``)
  ,("<Bool LShR(R27_3_32, 0x3d#32) != 0#32>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_RightShift (BExp_Den (BVar "R27" (BType_Imm Bit32)))
     (BExp_Const (Imm32 61w))) (BExp_Const (Imm32 0w))``)
  ,("<Bool LShR(R27_3_16 + 3#16 | R5_6_16, 0x3d#16) != 0#16>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_RightShift
     (BExp_BinExp BIExp_Or
        (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R27" (BType_Imm Bit16)))
           (BExp_Const (Imm16 3w))) (BExp_Den (BVar "R5" (BType_Imm Bit16))))
     (BExp_Const (Imm16 61w))) (BExp_Const (Imm16 0w))``)
  ,("<Bool ~(R0_0_8 & 7#8) == 0#8>",
   ``BExp_BinPred BIExp_Equal
  (BExp_UnaryExp BIExp_Not
     (BExp_BinExp BIExp_And (BExp_Den (BVar "R0" (BType_Imm Bit8)))
        (BExp_Const (Imm8 7w)))) (BExp_Const (Imm8 0w))``)
  ,("<Bool ~R0_0_8 & 7#8 == 0#8>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_And
     (BExp_UnaryExp BIExp_Not (BExp_Den (BVar "R0" (BType_Imm Bit8))))
        (BExp_Const (Imm8 7w))) (BExp_Const (Imm8 0w))``)
  ,("<Bool ~R0_0_8 & ~R2_1_8 == 0#8>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_And
     (BExp_UnaryExp BIExp_Not (BExp_Den (BVar "R0" (BType_Imm Bit8))))
     (BExp_UnaryExp BIExp_Not (BExp_Den (BVar "R2" (BType_Imm Bit8)))))
           (BExp_Const (Imm8 0w))``)
  ,("<Bool SignExt(32, R2_3_32) != 1#32>",
   ``T``)
  (* ,("<Bool SignExt(24, R2_3_32) != 1#32>", *)
  (*  ``T``) *)
  ,("<Bool 0#32 .. R2_3_32 != 1#32>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_AppendMask
     [(31,0,BExp_Const (Imm32 0w));
      (31,0,BExp_Den (BVar "R2" (BType_Imm Bit32)))]) (BExp_Const (Imm32 1w))``)
  ,("<Bool R2_3_32 + 0xa#32 .. 0x8#32 ^ R3_4_32 != 1#32>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_AppendMask
     [(31,0,
       BExp_BinExp BIExp_Plus (BExp_Den (BVar "R2" (BType_Imm Bit32)))
         (BExp_Const (Imm32 10w)));
      (31,0,
       BExp_BinExp BIExp_Xor (BExp_Const (Imm32 8w))
         (BExp_Den (BVar "R3" (BType_Imm Bit32))))]) (BExp_Const (Imm32 1w))``)
  ,("<Bool R2_3_64[63:16] .. 0x8#32 .. R7_1_16 != 0#64>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_AppendMask
     [(63,16,BExp_Den (BVar "R2" (BType_Imm Bit64)));
      (31,0,BExp_Const (Imm32 8w));
      (15,0,BExp_Den (BVar "R7" (BType_Imm Bit16)))]) (BExp_Const (Imm64 0w))``)
  ,("<Bool R2_3_64[7:0] .. R7_1_64 - 0xf#64[7:0] != 0#16>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_AppendMask
     [(7,0,BExp_Den (BVar "R2" (BType_Imm Bit64)));
      (7,0,
       BExp_BinExp BIExp_Minus (BExp_Den (BVar "R7" (BType_Imm Bit64)))
         (BExp_Const (Imm64 15w)))]) (BExp_Const (Imm16 0w))``)
  ,("<Bool ((((R5_8_64) + (MEM[<BV64 (R1_4_64) + (R3_6_64)>]_13_64))[7:0]) & (0x7#8)) == (0x0#8)>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_And
     (BExp_CastMask Bit64 7 0
        (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R5" (BType_Imm Bit64)))
           (BExp_Load (BExp_Den (BVar "MEM" (BType_Mem Bit64 Bit8)))
              (BExp_BinExp BIExp_Plus
                 (BExp_Den (BVar "R1" (BType_Imm Bit64)))
                 (BExp_Den (BVar "R3" (BType_Imm Bit64)))) BEnd_LittleEndian
              Bit64)) (THE (bir_immtype_of_size 8))) (BExp_Const (Imm8 7w)))
  (BExp_Const (Imm8 0w))``)
  ,("<Bool (R5_8_64 + (MEM[<BV64 R1_4_64 + R3_6_64>]_13_64 << 0xd#64)[7:0] & 7#8) == 0#8>",
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_And
     (BExp_CastMask Bit64 7 0
        (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R5" (BType_Imm Bit64)))
           (BExp_BinExp BIExp_LeftShift
              (BExp_Load (BExp_Den (BVar "MEM" (BType_Mem Bit64 Bit8)))
                 (BExp_BinExp BIExp_Plus
                    (BExp_Den (BVar "R1" (BType_Imm Bit64)))
                    (BExp_Den (BVar "R3" (BType_Imm Bit64))))
                 BEnd_LittleEndian Bit64) (BExp_Const (Imm64 13w))))
        (THE (bir_immtype_of_size 8))) (BExp_Const (Imm8 7w)))
  (BExp_Const (Imm8 0w))``)
  ,("<Bool R1_4_64 + R3_6_64[63:32] == 0#32>",
   ``BExp_BinPred BIExp_Equal
  (BExp_CastMask Bit64 63 32
     (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R1" (BType_Imm Bit64)))
        (BExp_Den (BVar "R3" (BType_Imm Bit64))))
     (THE (bir_immtype_of_size 32))) (BExp_Const (Imm32 0w))``)
  ,("<Bool ((R5_8_32) + (((R1_4_64) + (R3_6_64))[63:32])) == (0#32)>",
   (* Note: the same expression without any brackets breaks the parser *)
   ``BExp_BinPred BIExp_Equal
  (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R5" (BType_Imm Bit32)))
     (BExp_CastMask Bit64 63 32
        (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R1" (BType_Imm Bit64)))
           (BExp_Den (BVar "R3" (BType_Imm Bit64))))
        (THE (bir_immtype_of_size 32)))) (BExp_Const (Imm32 0w))``)
  ,("<Bool (if R7_10_64 - (R0_4_64 << 0x1d#64) <s 0x0#64 then 1#1 else 0#1) != (if R0_4_64 << 0x1d#64 <=s R7_10_64 then 1#1 else 0#1)>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_IfThenElse
     (BExp_BinPred BIExp_SignedLessThan
        (BExp_BinExp BIExp_Minus (BExp_Den (BVar "R7" (BType_Imm Bit64)))
           (BExp_BinExp BIExp_LeftShift
              (BExp_Den (BVar "R0" (BType_Imm Bit64)))
              (BExp_Const (Imm64 29w)))) (BExp_Const (Imm64 0w)))
     (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w)))
  (BExp_IfThenElse
     (BExp_BinPred BIExp_SignedLessOrEqual
        (BExp_BinExp BIExp_LeftShift (BExp_Den (BVar "R0" (BType_Imm Bit64)))
           (BExp_Const (Imm64 29w))) (BExp_Den (BVar "R7" (BType_Imm Bit64))))
     (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w)))``)
  ,("<Bool ((if R10_0_64 + 0x38#64 <= 0xffffffffffffffef#64 then 1#1 else 0#1) & ((if 0x0#64 < R10_0_64 + 0x38#64 then 1#1 else 0#1) | (if R10_0_64 + 0x48#64 <= 0x0#64 then 1#1 else 0#1)) & ((if R10_0_64 + 0x38#64 < 0x0#64 then 1#1 else 0#1) | (if 0x28#64 <= R10_0_64 + 0x38#64 then 1#1 else 0#1))) != 0#1>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_And
     (BExp_IfThenElse
        (BExp_BinPred BIExp_LessOrEqual
           (BExp_BinExp BIExp_Plus (BExp_Den (BVar "R10" (BType_Imm Bit64)))
              (BExp_Const (Imm64 56w)))
           (BExp_Const (Imm64 0xFFFFFFFFFFFFFFEFw))) (BExp_Const (Imm1 1w))
        (BExp_Const (Imm1 0w)))
     (BExp_BinExp BIExp_And
        (BExp_BinExp BIExp_Or
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessThan (BExp_Const (Imm64 0w))
                 (BExp_BinExp BIExp_Plus
                    (BExp_Den (BVar "R10" (BType_Imm Bit64)))
                    (BExp_Const (Imm64 56w)))) (BExp_Const (Imm1 1w))
              (BExp_Const (Imm1 0w)))
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessOrEqual
                 (BExp_BinExp BIExp_Plus
                    (BExp_Den (BVar "R10" (BType_Imm Bit64)))
                    (BExp_Const (Imm64 72w))) (BExp_Const (Imm64 0w)))
              (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w))))
        (BExp_BinExp BIExp_Or
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessThan
                 (BExp_BinExp BIExp_Plus
                    (BExp_Den (BVar "R10" (BType_Imm Bit64)))
                    (BExp_Const (Imm64 56w))) (BExp_Const (Imm64 0w)))
              (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w)))
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessOrEqual (BExp_Const (Imm64 40w))
                 (BExp_BinExp BIExp_Plus
                    (BExp_Den (BVar "R10" (BType_Imm Bit64)))
                    (BExp_Const (Imm64 56w)))) (BExp_Const (Imm1 1w))
              (BExp_Const (Imm1 0w)))))) (BExp_Const (Imm1 0w))``)
  ,("<Bool ((if R29_9_64 <= 0xfffffffffffffff7#64 then 1#1 else 0#1) & ((if 0x0#64 < R29_9_64 then 1#1 else 0#1) | (if 0x8#64 + R29_9_64 <= 0x0#64 then 1#1 else 0#1)) & ((if R29_9_64 < 0x0#64 then 1#1 else 0#1) | (if 0x28#64 <= R29_9_64 then 1#1 else 0#1))) != 0#1>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_And
     (BExp_IfThenElse
        (BExp_BinPred BIExp_LessOrEqual
           (BExp_Den (BVar "R29" (BType_Imm Bit64)))
           (BExp_Const (Imm64 0xFFFFFFFFFFFFFFF7w))) (BExp_Const (Imm1 1w))
        (BExp_Const (Imm1 0w)))
     (BExp_BinExp BIExp_And
        (BExp_BinExp BIExp_Or
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessThan (BExp_Const (Imm64 0w))
                 (BExp_Den (BVar "R29" (BType_Imm Bit64))))
              (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w)))
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessOrEqual
                 (BExp_BinExp BIExp_Plus (BExp_Const (Imm64 8w))
                    (BExp_Den (BVar "R29" (BType_Imm Bit64))))
                 (BExp_Const (Imm64 0w))) (BExp_Const (Imm1 1w))
              (BExp_Const (Imm1 0w))))
        (BExp_BinExp BIExp_Or
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessThan
                 (BExp_Den (BVar "R29" (BType_Imm Bit64)))
                 (BExp_Const (Imm64 0w))) (BExp_Const (Imm1 1w))
              (BExp_Const (Imm1 0w)))
           (BExp_IfThenElse
              (BExp_BinPred BIExp_LessOrEqual (BExp_Const (Imm64 40w))
                 (BExp_Den (BVar "R29" (BType_Imm Bit64))))
              (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w))))))
  (BExp_Const (Imm1 0w))``)
  ,("<Bool ((if 0x80100000#64 <= SP_EL0_8_64 + (~(LShR(0xffffe00000000003#64 & R20_6_64, 0x6#64) | (0xffffe00000000003#64 & R20_6_64) << 0x3a#64) & R0_4_64) + LShR(R0_4_64, 0x1a#64) then 1#1 else 0#1) & (if SP_EL0_8_64 + (~(LShR(0xffffe00000000003#64 & R20_6_64, 0x6#64) | (0xffffe00000000003#64 & R20_6_64) << 0x3a#64) & R0_4_64) + LShR(R0_4_64, 0x1a#64) < 0x8013ff80#64 then 1#1 else 0#1)) != 0#1>",
   ``BExp_BinPred BIExp_NotEqual
  (BExp_BinExp BIExp_And
     (BExp_IfThenElse
        (BExp_BinPred BIExp_LessOrEqual (BExp_Const (Imm64 0x80100000w))
           (BExp_BinExp BIExp_Plus
              (BExp_BinExp BIExp_Plus
                 (BExp_Den (BVar "SP_EL0" (BType_Imm Bit64)))
                 (BExp_UnaryExp BIExp_Not
                    (BExp_BinExp BIExp_And
                       (BExp_BinExp BIExp_Or
                          (BExp_BinExp BIExp_RightShift
                             (BExp_BinExp BIExp_And
                                (BExp_Const (Imm64 0xFFFFE00000000003w))
                                (BExp_Den (BVar "R20" (BType_Imm Bit64))))
                             (BExp_Const (Imm64 6w)))
                          (BExp_BinExp BIExp_LeftShift
                             (BExp_BinExp BIExp_And
                                (BExp_Const (Imm64 0xFFFFE00000000003w))
                                (BExp_Den (BVar "R20" (BType_Imm Bit64))))
                             (BExp_Const (Imm64 58w))))
                       (BExp_Den (BVar "R0" (BType_Imm Bit64))))))
              (BExp_BinExp BIExp_RightShift
                 (BExp_Den (BVar "R0" (BType_Imm Bit64)))
                 (BExp_Const (Imm64 26w))))) (BExp_Const (Imm1 1w))
        (BExp_Const (Imm1 0w)))
     (BExp_IfThenElse
        (BExp_BinPred BIExp_LessThan
           (BExp_BinExp BIExp_Plus
              (BExp_BinExp BIExp_Plus
                 (BExp_Den (BVar "SP_EL0" (BType_Imm Bit64)))
                 (BExp_UnaryExp BIExp_Not
                    (BExp_BinExp BIExp_And
                       (BExp_BinExp BIExp_Or
                          (BExp_BinExp BIExp_RightShift
                             (BExp_BinExp BIExp_And
                                (BExp_Const (Imm64 0xFFFFE00000000003w))
                                (BExp_Den (BVar "R20" (BType_Imm Bit64))))
                             (BExp_Const (Imm64 6w)))
                          (BExp_BinExp BIExp_LeftShift
                             (BExp_BinExp BIExp_And
                                (BExp_Const (Imm64 0xFFFFE00000000003w))
                                (BExp_Den (BVar "R20" (BType_Imm Bit64))))
                             (BExp_Const (Imm64 58w))))
                       (BExp_Den (BVar "R0" (BType_Imm Bit64))))))
              (BExp_BinExp BIExp_RightShift
                 (BExp_Den (BVar "R0" (BType_Imm Bit64)))
                 (BExp_Const (Imm64 26w)))) (BExp_Const (Imm64 0x8013FF80w)))
        (BExp_Const (Imm1 1w)) (BExp_Const (Imm1 0w))))
  (BExp_Const (Imm1 0w))``)
  
(*
  ,("<...>",
    ``T``)
*)
];

val _ = print "Running and checking test cases\n";

val fail_ref = ref false;
val num_success = ref 0;
val _ = List.map (fn (calripyexp, expectedterm) =>
  let
    val res = bir_angrLib.parse_guard calripyexp;
    val _ = if identical res expectedterm then (num_success := (!num_success + 1)) else (
            fail_ref := true;
            print ("--------------------------------------\n");
            print ("+++ test input: \n");
            PolyML.print calripyexp;
            print ("+++ have as result: \n");
            print_term res;
            print ("+++ expecting: \n");
            print_term expectedterm;
            print ("\n\n"));
  in () end) angr_exp_testcases;

val _ = print ("\n\n" ^ "number of successful test cases: " ^ (Int.toString (!num_success)) ^ "/" ^ (Int.toString (List.length angr_exp_testcases)) ^ "\n\n");

val _ = if not(!fail_ref) then () else
        raise Fail "some test case(s) failed";
