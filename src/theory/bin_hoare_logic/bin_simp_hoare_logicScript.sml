open HolKernel Parse boolLib bossLib;
open bin_hoare_logicTheory;
open bir_auxiliaryTheory;

open bir_auxiliaryLib;

val _ = new_theory "bin_simp_hoare_logic";

(* Inv is usually the fact that the program is in memory and that
 * the execution mode is the expected one *)
val weak_map_triple_def = Define `
  weak_map_triple (m:('a, 'b) bin_model_t) invar l ls ls' pre post =
    (((ls INTER ls') = EMPTY) /\
     (weak_triple m l invar (ls UNION ls')
                 (\ms. pre ms)
                 (\ms. if ((m.pc ms) IN ls') then F else (post ms))
     )
    )
`;


val weak_map_subset_blacklist_rule_thm = prove(``
  !m invar l ls ls' ls'' pre post.
  weak_model m ==>
  ls'' SUBSET ls' ==>
  weak_map_triple m invar l ls ls' pre post ==>
  weak_map_triple m invar l ls ls'' pre post``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [weak_map_triple_def] >>
ASSUME_TAC (ISPECL [``ls'':'b->bool``, ``ls':'b->bool``, ``ls:'b->bool``] INTER_SUBSET_EMPTY_thm) >>
REV_FULL_SIMP_TAC std_ss [] >>
irule weak_weakening_rule_thm >>
subgoal `?v. ls' = ls'' UNION v` >- (
  METIS_TAC [SUBSET_EQ_UNION_thm]
) >>
REV_FULL_SIMP_TAC std_ss [] >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `invar` >>
Q.EXISTS_TAC `(\ms:'a. m.pc ms NOTIN (ls'':'b->bool) UNION v /\ post ms)` >>
Q.EXISTS_TAC `\ms. pre ms` >>
subgoal `!ms. ((\ms. m.pc ms NOTIN ls'' UNION v /\ post ms)) ms ==>
              m.pc ms NOTIN v` >- (
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) [] 
) >>
Q.SUBGOAL_THEN `(ls UNION (ls'' UNION v)) = ((ls UNION ls'') UNION v)`
  (fn thm => FULL_SIMP_TAC std_ss [thm]) >- (
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) []
) >>
ASSUME_TAC (Q.SPECL [`m`, `l`, `invar`, `ls UNION ls''`, `v`,
	   `\ms:'a. pre ms`,
	   `\ms:'a. m.pc ms NOTIN (ls'':'b->bool) UNION v /\ post ms`] 
  weak_subset_rule_thm) >>
REV_FULL_SIMP_TAC std_ss [] >>
subgoal `!ms. ((m.pc ms) IN (ls UNION ls'')) ==>
              ((\ms. m.pc ms NOTIN ls'' UNION v /\ post ms) ms) ==>
              ((\ms. m.pc ms NOTIN ls'' /\ post ms) ms)` >- (
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) []
) >>
METIS_TAC []
);


val weak_map_move_to_blacklist = store_thm("weak_map_move_to_blacklist",
  ``!m invar l l' ls ls' pre post.
    weak_model m ==>
    l' IN ls ==>
    (!ms. (m.pc ms = l') ==> (post ms = F)) ==>
    weak_map_triple m invar l ls ls' pre post ==>
    weak_map_triple m invar l (ls DELETE l') (l' INSERT ls') pre post``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [weak_map_triple_def, weak_triple_def] >>
subgoal `?ls''. (ls = l' INSERT ls'') /\ l' NOTIN ls''` >- (
  METIS_TAC [pred_setTheory.DECOMPOSITION]
) >>
subgoal `l' NOTIN ls'` >- (
  METIS_TAC [pred_setTheory.INSERT_INTER, pred_setTheory.NOT_INSERT_EMPTY]
) >>
REPEAT STRIP_TAC >| [
  FULL_SIMP_TAC std_ss [pred_setTheory.DELETE_INTER, pred_setTheory.INSERT_INTER,
                        pred_setTheory.COMPONENT] >>
  ONCE_REWRITE_TAC [pred_setTheory.INTER_COMM] >>
  FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) [pred_setTheory.INSERT_INTER,
                                                   pred_setTheory.COMPONENT,
                                                   pred_setTheory.INSERT_EQ_SING] >>
  `ls'' SUBSET ls` suffices_by (
    FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) [pred_setTheory.INTER_COMM]
  ) >>
  FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) [],

  QSPECL_X_ASSUM ``!ms. (m.pc ms = l) ==> _`` [`ms`] >>
  REV_FULL_SIMP_TAC std_ss [] >>
  QSPECL_X_ASSUM ``!ms. _`` [`ms'`] >>
  Q.EXISTS_TAC `ms'` >>
  subgoal `m.pc ms' <> l'` >- (
    CCONTR_TAC >>
    FULL_SIMP_TAC std_ss []
  ) >>
  FULL_SIMP_TAC (std_ss++pred_setLib.PRED_SET_ss) [] >>
  `((l' INSERT ls'') DELETE l' UNION (l' INSERT ls')) = ((l' INSERT ls'') UNION ls')` suffices_by (
    FULL_SIMP_TAC std_ss []
  ) >>
  METIS_TAC [pred_setTheory.UNION_COMM, pred_setTheory.INSERT_UNION_EQ,
             pred_setTheory.DELETE_INSERT, pred_setTheory.DELETE_NON_ELEMENT]
]
);


val weak_map_weakening_rule_thm = store_thm("weak_map_weakening_rule_thm",
  ``!m invar l ls ls' pre post1 post2.
    weak_model m ==>
    (!ms. (m.pc ms) IN ls ==> (post1 ms) ==> (post2 ms)) ==>
    weak_map_triple m invar l ls ls' pre post1 ==>
    weak_map_triple m invar l ls ls' pre post2``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [weak_map_triple_def] >>
irule weak_weakening_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `invar` >>
Q.EXISTS_TAC `\ms. m.pc ms NOTIN (ls':'b->bool) /\ post1 ms` >>
Q.EXISTS_TAC `\ms. pre ms` >>
subgoal `!ms. m.pc ms IN (ls UNION ls') ==>
         (\ms. m.pc ms NOTIN ls' /\ post1 ms) ms ==>
         (\ms. m.pc ms NOTIN ls' /\ post2 ms) ms` >- (
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) []
) >>
REV_FULL_SIMP_TAC std_ss []
);

val weak_map_strengthening_rule_thm = store_thm("weak_map_strengthening_rule_thm",
  ``!m invar l ls ls' pre1 pre2 post.
    weak_model m ==>
    (!ms. ((m.pc ms) = l) ==> (pre2 ms) ==> (pre1 ms)) ==>
    weak_map_triple m invar l ls ls' pre1 post ==>
    weak_map_triple m invar l ls ls' pre2 post``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [weak_map_triple_def] >>
irule weak_weakening_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `invar` >>
Q.EXISTS_TAC `\ms. m.pc ms NOTIN (ls':'b->bool) /\ post ms` >>
Q.EXISTS_TAC `\ms. pre1 ms` >>
subgoal `!ms. (m.pc ms = l) ==>
         (\ms. pre2 ms) ms ==>
         (\ms. pre1 ms) ms` >- (
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) []
) >>
REV_FULL_SIMP_TAC std_ss []
);


val weak_map_add_post_corollary_thm = prove(``
  !m invar l ls ls' pre post1 post2.
  weak_model m ==>
  weak_map_triple m invar l ls ls' pre post1 ==>
  weak_map_triple m invar l ls ls' pre (\ms. if m.pc ms IN ls then post1 ms else post2 ms)``,

REPEAT STRIP_TAC >>
irule weak_map_weakening_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `post1` >>
REV_FULL_SIMP_TAC std_ss []
);


val weak_map_add_post2_corollary = prove(``
  !m invar l ls1 ls2 ls' pre post1 post2.
  weak_model m ==>
  ((ls1 INTER ls2) = EMPTY) ==>
  weak_map_triple m invar l ls1 ls' pre post1 ==>
  weak_map_triple m invar l ls1 ls' pre (\ms. if (m.pc ms IN ls2) then post2 ms else post1 ms)``,

REPEAT STRIP_TAC >>
irule weak_map_weakening_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `post1` >>
subgoal `!ms. m.pc ms IN ls1 ==> post1 ms ==>
         (\ms. if m.pc ms IN ls2 then post2 ms else post1 ms) ms` >- (
  REPEAT STRIP_TAC >>
  METIS_TAC [INTER_EMPTY_IN_NOT_IN_thm]
) >>
REV_FULL_SIMP_TAC std_ss [] 
);


(* This proof should use the blacklist move lemma *)
val weak_map_seq_thm = prove(
  ``!m invar l ls1 ls ls' pre post.
    weak_model m ==>
    (ls INTER ls' = {}) ==>
    weak_map_triple m invar l ls1 (ls UNION ls') pre post ==>
    (!l1.
     (l1 IN ls1) ==>
     weak_map_triple m invar l1 ls ls' post post
    ) ==>
    (weak_map_triple m invar l ls ls' pre post)``,

REPEAT STRIP_TAC >>
FULL_SIMP_TAC std_ss [weak_map_triple_def] >>
irule weak_seq_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `ls1` >>
(* Massage first contract *)
subgoal `weak_triple m l invar (ls1 UNION (ls UNION ls')) (\ms. pre ms)
           (\ms. m.pc ms NOTIN ls' /\ post ms)` >- (
  irule weak_weakening_rule_thm >>
  FULL_SIMP_TAC std_ss [] >>
  Q.EXISTS_TAC `invar` >>
  Q.EXISTS_TAC `\ms. m.pc ms NOTIN ls UNION ls' /\ post ms` >>
  Q.EXISTS_TAC `\ms. pre ms` >>
  subgoal `(!ms. m.pc ms IN (ls1 UNION (ls UNION ls')) ==>
	   (\ms. m.pc ms NOTIN ls UNION ls' /\ post ms) ms ==>
	   (\ms. m.pc ms NOTIN ls' /\ post ms) ms)` >- (
    FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) []
  ) >>
  FULL_SIMP_TAC std_ss []
) >>
(* Massage the second contract *)
subgoal `!l1. l1 IN ls1 ==>
         weak_triple m l1 invar (ls UNION ls') (\ms. m.pc ms NOTIN ls' /\ post ms)
         (\ms. m.pc ms NOTIN ls' /\ post ms)` >- (
  REPEAT STRIP_TAC >>
  irule weak_weakening_rule_thm >>
  FULL_SIMP_TAC std_ss [] >>
  Q.EXISTS_TAC `invar` >>
  Q.EXISTS_TAC `\ms. m.pc ms NOTIN ls' /\ post ms` >>
  Q.EXISTS_TAC `\ms. post ms` >>
  subgoal `!ms.
           (m.pc ms = l1) ==>
           (\ms. post ms) ms ==>
           (\ms. m.pc ms NOTIN ls' /\ post ms) ms` >- (
    REPEAT STRIP_TAC >>
    FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss) [] >>
    FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_AC_ss++pred_setSimps.PRED_SET_ss)
      [pred_setTheory.UNION_OVER_INTER] >>
    METIS_TAC [INTER_EMPTY_IN_NOT_IN_thm]
  ) >>
  FULL_SIMP_TAC std_ss []
) >>
FULL_SIMP_TAC std_ss []
);


(* We should generalize the other contract to handle set of labels *)
val weak_map_std_seq_comp_thm = store_thm("weak_map_std_seq_comp_thm",
  ``!m ls1 ls1' ls2 ls2' invar l pre1 post1 post2.
    weak_model m ==>
    ls1' SUBSET ls2 ==>
    (ls1 INTER ls1' = EMPTY) ==>
    (ls1' INTER ls2' = EMPTY) ==>
    weak_map_triple m invar l ls1 ls2 pre1 post1 ==>
    (!l1. (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' post1 post2)) ==>
    weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2``,

REPEAT STRIP_TAC >>
irule weak_map_weakening_rule_thm >>
FULL_SIMP_TAC std_ss [] >>
Q.EXISTS_TAC `(\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >>
(* First we extend the initial contract to have the same postcondition *)
subgoal `weak_map_triple m invar l ls1 ls2 pre1
           (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
  METIS_TAC [weak_map_add_post_corollary_thm]
) >>
(* We then restrict the non-accessible addresses of the first contract *)
subgoal `ls1' UNION (ls2 INTER ls2') SUBSET ls2` >- (
  FULL_SIMP_TAC (std_ss++pred_setSimps.PRED_SET_ss) []
) >>
subgoal `weak_map_triple m invar l ls1 (ls1' UNION ls2 INTER ls2') pre1
           (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
  METIS_TAC [weak_map_subset_blacklist_rule_thm]
) >>
(* Now, we extend the second contracts *)
subgoal `!l1.
         l1 IN ls1 ==>
         weak_map_triple m invar l1 ls1' (ls2 INTER ls2')
           ((\ms. if m.pc ms IN ls1 then post1 ms else post2 ms))
             (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
  REPEAT STRIP_TAC >>
  QSPECL_X_ASSUM ``!l1. _`` [`l1`] >>  
  REV_FULL_SIMP_TAC std_ss [] >>
  (* Now, we extend the second contract to have the same postcondition *)
  subgoal `weak_map_triple m invar l1 ls1' ls2' post1
             (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
    METIS_TAC [weak_map_add_post2_corollary, pred_setTheory.INTER_COMM]
  ) >>
  (* We then restrict the non-accessible addresses of the first contract *)
  subgoal `weak_map_triple m invar l1 ls1' (ls2 INTER ls2') post1
             (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
    METIS_TAC [weak_map_subset_blacklist_rule_thm, pred_setTheory.INTER_SUBSET]
  ) >>
  FULL_SIMP_TAC std_ss [weak_triple_def, weak_map_triple_def]
) >>
subgoal `weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1
           (\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)` >- (
  ASSUME_TAC (Q.SPECL [`m`, `invar`, `l`, `ls1`, `ls1'`, `(ls2 INTER ls2')`,
                       `pre1`, `(\ms. if m.pc ms IN ls1 then post1 ms else post2 ms)`]
    weak_map_seq_thm
  ) >>
  METIS_TAC [INTER_EMPTY_INTER_INTER_EMPTY_thm, pred_setTheory.INTER_COMM]
) >>
subgoal `(!ms. m.pc ms IN ls1' ==>
	  (\ms.
	   if m.pc ms IN ls1
	   then post1 ms
	   else post2 ms) ms ==>
	   post2 ms)` >- (
  REPEAT STRIP_TAC >>
  FULL_SIMP_TAC std_ss [] >>
  subgoal `~(m.pc ms IN ls1)` >- (
    METIS_TAC [INTER_EMPTY_IN_NOT_IN_thm]
  ) >>
  FULL_SIMP_TAC std_ss [] 
) >>
(* Finish everything... *)
FULL_SIMP_TAC std_ss []
);

(* The below are still TODO: *)
(*
(* Condition *)
val weak_map_std_seq_comp_thm = prove(``
(weak_model m) ==>
(ls1' SUBSET ls2) ==>
(ls1 INTER ls1' = EMPTY) ==>
(ls1' INTER ls2' = EMPTY) ==>
(weak_map_triple m invar l ls1 ls2 pre1 post1) ==>
(!l1 . (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' (post1 l1) post2)) ==>
(weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2)
``,

cheat);


(* Loop *)
val weak_map_std_seq_comp_thm = prove(``
(weak_model m) ==>
(ls1' SUBSET ls2) ==>
(ls1 INTER ls1' = EMPTY) ==>
(ls1' INTER ls2' = EMPTY) ==>
(weak_map_triple m invar l ls1 ls2 pre1 post1) ==>
(!l1 . (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' (post1 l1) post2)) ==>
(weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2)
``,cheat);


(* Function call *)
val weak_map_std_seq_comp_thm = prove(``
(weak_model m) ==>
(ls1' SUBSET ls2) ==>
(ls1 INTER ls1' = EMPTY) ==>
(ls1' INTER ls2' = EMPTY) ==>
(weak_map_triple m invar l ls1 ls2 pre1 post1) ==>
(!l1 . (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' (post1 l1) post2)) ==>
(weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2)
``,

cheat);


(* Recursive function *)
val weak_map_std_seq_comp_thm = prove(``
(weak_model m) ==>
(ls1' SUBSET ls2) ==>
(ls1 INTER ls1' = EMPTY) ==>
(ls1' INTER ls2' = EMPTY) ==>
(weak_map_triple m invar l ls1 ls2 pre1 post1) ==>
(!l1 . (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' (post1 l1) post2)) ==>
(weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2)
``,

cheat);


(* Mutually Recursive function *)
val weak_map_std_seq_comp_thm = prove(``
(weak_model m) ==>
(ls1' SUBSET ls2) ==>
(ls1 INTER ls1' = EMPTY) ==>
(ls1' INTER ls2' = EMPTY) ==>
(weak_map_triple m invar l ls1 ls2 pre1 post1) ==>
(!l1 . (l1 IN ls1) ==> (weak_map_triple m invar l1 ls1' ls2' (post1 l1) post2)) ==>
(weak_map_triple m invar l ls1' (ls2 INTER ls2') pre1 post2)
``,

cheat);
*)

val _ = export_theory();



