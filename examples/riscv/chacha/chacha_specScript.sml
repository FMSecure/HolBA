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

Definition chacha_line:
 chacha_line (a:word32) (b:word32) (d:word32) (s:word32)
  (m:word32 -> word32) =
  let m = (a =+ (m a) + (m b)) m in
  let m = (d =+ ((m d) ?? (m a)) #<<~ s) m in
  m
End

(*
op quarter_round a b c d : shuffle =
  line a b d 16 \oo
  line c d b 12 \oo
  line a b d 8  \oo
  line c d b 7.
*)

Definition chacha_quarter_round:
 chacha_quarter_round (a:word32) (b:word32) (c:word32) (d:word32) =
  chacha_line c d b 7w o
  chacha_line a b d 8w o 
  chacha_line c d b 12w o 
  chacha_line a b d 16w
End

(*
op column_round : shuffle =
  quarter_round 0 4 8  12 \oo
  quarter_round 1 5 9  13 \oo
  quarter_round 2 6 10 14 \oo
  quarter_round 3 7 11 15.
*)
        
Definition chacha_column_round:
 chacha_column_round =
  chacha_quarter_round 3w 7w 11w 15w o
  chacha_quarter_round 2w 6w 10w 14w o
  chacha_quarter_round 1w 5w 9w 13w o
  chacha_quarter_round 0w 4w 8w 12w
End

(*
op diagonal_round : shuffle =
  quarter_round 0 5 10 15 \oo
  quarter_round 1 6 11 12 \oo
  quarter_round 2 7 8  13 \oo
  quarter_round 3 4 9  14.
*)

Definition chacha_diagonal_round:
 chacha_diagonal_round =
  chacha_quarter_round 3w 4w 9w 14w o
  chacha_quarter_round 2w 7w 8w 13w o
  chacha_quarter_round 1w 6w 11w 12w o
  chacha_quarter_round 0w 5w 10w 15w
End

(*
op double_round: shuffle =
  column_round \oo diagonal_round.
*)

Definition chacha_double_round:
 chacha_double_round =
  chacha_diagonal_round o chacha_column_round
End

Definition chacha_rounds:
 chacha_rounds =
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round o
  chacha_double_round
End

Definition chacha_add_16:
 chacha_add_16 (s: word32 -> word32)
  (s' : word32 -> word32) : word32 -> word32 =
  let m = s in
  let m = (0w =+ (s 0w) + (s' 0w)) m in
  let m = (1w =+ (s 1w) + (s' 1w)) m in
  let m = (2w =+ (s 2w) + (s' 2w)) m in
  let m = (3w =+ (s 3w) + (s' 3w)) m in
  let m = (4w =+ (s 4w) + (s' 4w)) m in
  let m = (5w =+ (s 5w) + (s' 5w)) m in
  let m = (6w =+ (s 6w) + (s' 6w)) m in
  let m = (7w =+ (s 7w) + (s' 7w)) m in
  let m = (8w =+ (s 8w) + (s' 8w)) m in
  let m = (9w =+ (s 9w) + (s' 9w)) m in
  let m = (10w =+ (s 10w) + (s' 10w)) m in
  let m = (11w =+ (s 11w) + (s' 11w)) m in
  let m = (12w =+ (s 12w) + (s' 12w)) m in
  let m = (13w =+ (s 13w) + (s' 13w)) m in
  let m = (14w =+ (s 14w) + (s' 14w)) m in
  let m = (15w =+ (s 15w) + (s' 15w)) m in
  m
End

Definition chacha_core:
 chacha_core (s:word32 -> word32) : word32 -> word32 =
  let s' = chacha_rounds s in
  chacha_add_16 s' s
End

Definition chacha_setup:
 chacha_setup (k : word32 -> word32)
  (n : word32 -> word32) (c : word32) : word32 -> word32 =
  let m = ARB in
  let m = (0w =+ 0x61707865w) m in
  let m = (1w =+ 0x3320646ew) m in
  let m = (2w =+ 0x79622d32w) m in
  let m = (3w =+ 0x6b206574w) m in
  let m = (4w =+ (k 0w)) m in
  let m = (5w =+ (k 1w)) m in
  let m = (6w =+ (k 2w)) m in
  let m = (7w =+ (k 3w)) m in
  let m = (8w =+ (k 4w)) m in
  let m = (9w =+ (k 5w)) m in
  let m = (10w =+ (k 6w)) m in
  let m = (11w =+ (k 7w)) m in
  let m = (12w =+ c) m in
  let m = (13w =+ (n 0w)) m in
  let m = (14w =+ (n 1w)) m in
  let m = (15w =+ (n 2w)) m in
  m
End

(* Examples and validation *)

Definition chacha_example_state_row:
 chacha_example_state_row : word32 -> word32 =
  let m = ARB in
  let m = (0w =+ 0x11111111w) m in
  let m = (1w =+ 0x01020304w) m in
  let m = (2w =+ 0x9b8d6f43w) m in
  let m = (3w =+ 0x01234567w) m in
  m
End

Definition chacha_example_state_full:
 chacha_example_state_full : word32 -> word32 =
  let m = ARB in
  let m = (0w =+ 0x879531e0w) m in
  let m = (1w =+ 0xc5ecf37dw) m in
  let m = (2w =+ 0x516461b1w) m in
  let m = (3w =+ 0xc9a62f8aw) m in
  let m = (4w =+ 0x44c20ef3w) m in
  let m = (5w =+ 0x3390af7fw) m in
  let m = (6w =+ 0xd9fc690bw) m in
  let m = (7w =+ 0x2a5f714cw) m in
  let m = (8w =+ 0x53372767w) m in
  let m = (9w =+ 0xb00a5631w) m in
  let m = (10w =+ 0x974c541aw) m in
  let m = (11w =+ 0x359e9963w) m in
  let m = (12w =+ 0x5c971061w) m in
  let m = (13w =+ 0x3d631689w) m in
  let m = (14w =+ 0x2098d9d6w) m in
  let m = (15w =+ 0x91dbd320w) m in
  m
End

(* RFC7539 2.1.1 example *)
Theorem chacha_example_quarter_round_row[local]:
 chacha_quarter_round 0w 1w 2w 3w chacha_example_state_row 0w = 0xea2a92f4w
 /\
 chacha_quarter_round 0w 1w 2w 3w chacha_example_state_row 1w = 0xcb1cf8cew
 /\
 chacha_quarter_round 0w 1w 2w 3w chacha_example_state_row 2w = 0x4581472ew
 /\
 chacha_quarter_round 0w 1w 2w 3w chacha_example_state_row 3w = 0x5881c4bbw
Proof
 EVAL_TAC
QED

(* RFC7539 2.2.1 example *)
Theorem chacha_example_quarter_round_full[local]:
 chacha_quarter_round 2w 7w 8w 13w chacha_example_state_full 2w = 0xbdb886dcw
 /\
 chacha_quarter_round 2w 7w 8w 13w chacha_example_state_full 7w = 0xcfacafd2w
 /\
 chacha_quarter_round 2w 7w 8w 13w chacha_example_state_full 8w = 0xe46bea80w
 /\
 chacha_quarter_round 2w 7w 8w 13w chacha_example_state_full 13w = 0xccc07c79w
Proof
 EVAL_TAC
QED

Definition chacha_example_state_key_setup:
 chacha_example_state_key_setup : word32 -> word32 =
  let m = ARB in
  let m = (0w =+ 0x61707865w) m in
  let m = (1w =+ 0x3320646ew) m in
  let m = (2w =+ 0x79622d32w) m in
  let m = (3w =+ 0x6b206574w) m in
  let m = (4w =+ 0x03020100w) m in
  let m = (5w =+ 0x07060504w) m in
  let m = (6w =+ 0x0b0a0908w) m in
  let m = (7w =+ 0x0f0e0d0cw) m in
  let m = (8w =+ 0x13121110w) m in
  let m = (9w =+ 0x17161514w) m in
  let m = (10w =+ 0x1b1a1918w) m in
  let m = (11w =+ 0x1f1e1d1cw) m in
  let m = (12w =+ 0x00000001w) m in
  let m = (13w =+ 0x09000000w) m in
  let m = (14w =+ 0x4a000000w) m in
  let m = (15w =+ 0x00000000w) m in
  m
End

(* RFC7539 2.3.2 example *)
Theorem chacha_example_state_key_setup[local]:
 chacha_rounds chacha_example_state_key_setup 0w = 0x837778abw
 /\
 chacha_rounds chacha_example_state_key_setup 1w = 0xe238d763w
 /\
 chacha_rounds chacha_example_state_key_setup 2w = 0xa67ae21ew
 /\
 chacha_rounds chacha_example_state_key_setup 3w = 0x5950bb2fw
Proof
 EVAL_TAC
QED

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

(* first quarterround *)

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

(*
1.  a += b; d ^= a; d <<<= 16;
2.  c += d; b ^= c; b <<<= 12;
3.  a += b; d ^= a; d <<<= 8;
4.  c += d; b ^= c; b <<<= 7;

x20 <- x10 + x22  // a += b
x26 <- x20 ^ x26  // d ^= a
x10 <- x26 lsl 16
x26 <- x26 lsr 16
x10 <- x10 | x26  // d <<<= 16

x8 <- x28 + x10   // c += d
x22 <- x8 ^ x22   // b ^= c
x15 <- x22 lsl 12
x22 <- x22 lsr 20
x15 <- x15 | x22  // b <<<= 12

x20 <- x15 + x20  // a += b
x10 <- x20 ^ x10  // d ^= a
x22 <- x10 lsl 8
x10 <- x10 lsr 24
x22 <- x10 | x22  // d <<<= 8

x8 <- x8 + x22    // c += d
x15 <- x15 ^ x8   // b ^= c
x21 <- x15 lsl 7
x15 <- x15 lsr 25
x21 <- x15 | x21  // b <<<= 7

*)
val bspec_chacha_quarterround_pre_tm = bslSyntax.bandl [
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x10",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x11",
  mem_addrs_aligned_prog_disj_bir_tm mem_params_standard "x12",
  ``BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x10" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x10))``,
  ``BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x20" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x20))``,
  ``BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x22" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x22))``,
  ``BExp_BinPred
    BIExp_Equal
    (BExp_Den (BVar "x26" (BType_Imm Bit64)))
    (BExp_Const (Imm64 pre_x26))``
  
];

Definition bspec_chacha_quarterround_pre_def:
 bspec_chacha_quarterround_pre (pre_x10:word64) 
  (pre_x20:word64) (pre_x22:word64) (pre_x26:word64) : bir_exp_t =
  ^bspec_chacha_quarterround_pre_tm
End

val bspec_chacha_quarterround_post_tm = bslSyntax.bandl [
  ``BExp_BinPred
   BIExp_Equal
   (BExp_Den (BVar "x20" (BType_Imm Bit64)))
   (BExp_Cast BIExp_SignedCast
    (BExp_Cast BIExp_LowCast 
     (BExp_BinExp BIExp_Plus
       (BExp_Const (Imm64 pre_x10))
       (BExp_Const (Imm64 pre_x22)))
     Bit32) Bit64)``
];

Definition bspec_chacha_quarterround_post_def:
 bspec_chacha_quarterround_post (pre_x10:word64) 
  (pre_x20:word64) (pre_x22:word64) (pre_x26:word64)
  : bir_exp_t =
  ^bspec_chacha_quarterround_post_tm
End

val _ = export_theory ();
