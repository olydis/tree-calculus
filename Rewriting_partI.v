(**********************************************************************)
(* Copyright 2020 Barry Jay                                           *)
(*                                                                    *) 
(* Permission is hereby granted, free of charge, to any person        *) 
(* obtaining a copy of this software and associated documentation     *) 
(* files (the "Software"), to deal in the Software without            *) 
(* restriction, including without limitation the rights to use, copy, *) 
(* modify, merge, publish, distribute, sublicense, and/or sell copies *) 
(* of the Software, and to permit persons to whom the Software is     *) 
(* furnished to do so, subject to the following conditions:           *) 
(*                                                                    *) 
(* The above copyright notice and this permission notice shall be     *) 
(* included in all copies or substantial portions of the Software.    *) 
(*                                                                    *) 
(* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,    *) 
(* EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF *) 
(* MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND              *) 
(* NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT        *) 
(* HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,       *) 
(* WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, *) 
(* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER      *) 
(* DEALINGS IN THE SOFTWARE.                                          *) 
(**********************************************************************)

(**********************************************************************)
(*              Reflective Programs in Tree Calculus                  *)
(*               Chapter 7: Rewriting (of Part I)                     *)
(*                                                                    *)
(*                     Barry Jay                                      *)
(*                                                                    *)
(**********************************************************************)

(* 
Reprise all of the results in Part I using rewriting instead of equational reasoning. 
The development must begin from scratch to avoid the equational axioms in Tree_Calculus.v 
*)

Require Import Bool List String Lia.

Set Default Proof Using "Type".

Open Scope string_scope.

Ltac caseEq f := generalize (refl_equal f); pattern f at -1; case f. 
Ltac auto_t:= eauto with TreeHintDb. 
Ltac eapply2 H := eapply H; auto_t; try lia.
Ltac split_all := simpl; intros; 
match goal with 
| H : _ /\ _ |- _ => inversion_clear H; split_all
| H : exists _, _ |- _ => inversion H; clear H; split_all 
| _ =>  try (split; split_all); try contradiction
end; try congruence; auto_t.
Ltac exist x := exists x; split_all.

Declare Scope tree_scope.
Open Scope tree_scope.

(* Chapter 3: Tree Calculus *)

(* 3.3: Tree Calculus *)

Inductive Tree:  Set :=
  | Ref : string -> Tree  (* variables are indexed by strings *) 
  | Node : Tree   
  | App : Tree -> Tree -> Tree   
.

Hint Constructors Tree : TreeHintDb.


Notation "△" := Node : tree_scope.
Notation "x @ y" := (App x y) (at level 65, left associativity) : tree_scope.


Definition K := △ @ △. 
Definition I := △ @ (△ @ △) @ (△ @ △).
Definition KI := K@I. 
Definition D := △ @ (△ @ △) @ (△ @ △ @ △).
Definition d x := △ @ (△@x).
Definition Sop := △@(△@(△ @ △ @ D))@(△@(△@K)@(K@D)). 
Ltac unfold_op := unfold Sop, D, KI, I, K.


Fixpoint term_size M :=
  match M with
  | M1 @ M2 => term_size M1 + term_size M2
  |  _ => 1
  end.

Lemma size_positive: forall M, term_size M >0.
Proof. induction M; split_all; lia. Qed.


Ltac inv1 prop :=
match goal with
| H: prop (Ref _) |- _ => inversion H; clear H; inv1 prop
| H: prop (_ @ _) |- _ => inversion H; clear H; inv1 prop
| H: prop △ |- _ => inversion H; clear H; inv1 prop
| _ => auto_t
 end.


(* Tree-reduction *) 
Inductive t_red1 : Tree -> Tree -> Prop :=
| k_red : forall M N, t_red1 (△@△@M@N) M 
| s_red: forall (M N P : Tree), t_red1 (△@(△@P)@M@N) (M@N@(P@N))
| f_red : forall (P Q M N: Tree), t_red1 (△@(△@P@Q)@M@N) (N@P@Q)
| appl_red : forall M M' N, t_red1 M M' -> t_red1 (M@N) (M'@N)  
| appr_red : forall M N N', t_red1 N N' -> t_red1 (M@N) (M@N')  
.
Hint Constructors t_red1 : TreeHintDb. 

(* Multiple reduction steps *) 

Inductive multi_step : (Tree -> Tree -> Prop) -> Tree -> Tree -> Prop :=
  | zero_red : forall red M, multi_step red M M
  | succ_red : forall (red: Tree-> Tree -> Prop) M N P, 
                   red M N -> multi_step red N P -> multi_step red M P
.
Hint Constructors multi_step: TreeHintDb.  


Definition transitive red := forall (M N P: Tree), red M N -> red N P -> red M P. 

Lemma transitive_red : forall red, transitive (multi_step red). 
Proof. red; induction 1; split_all; eapply2 succ_red. Qed. 

Definition preserves_appl (red : Tree -> Tree -> Prop) := 
forall M N M', red M M' -> red (M@N) (M'@ N).

Definition preserves_appr (red : Tree -> Tree -> Prop) := 
forall M N N', red N N' -> red (M@N) (M@N').

Definition preserves_app (red : Tree -> Tree -> Prop) := 
forall M M', red M M' -> forall N N', red N N' -> red (M@N) (M'@N').

Lemma preserves_appl_multi_step : 
forall (red: Tree -> Tree -> Prop), preserves_appl red -> preserves_appl (multi_step red). 
Proof. red; intros red pa M N M' r ; induction r; auto_t; eapply2 succ_red. Qed.

Lemma preserves_appr_multi_step : 
forall (red: Tree -> Tree -> Prop), preserves_appr red -> preserves_appr (multi_step red). 
Proof. red; intros red pa M N M' r ; induction r; auto_t; eapply2 succ_red. Qed.

Lemma preserves_app_multi_step : 
  forall (red: Tree -> Tree -> Prop),
    preserves_appl red -> preserves_appr red -> 
    preserves_app (multi_step red). 
Proof.
  red; intros; apply transitive_red with (M'@N); 
    [ apply preserves_appl_multi_step |
      apply preserves_appr_multi_step]
    ; auto.
Qed.


Ltac inv red := 
match goal with 
| H: multi_step red (_ @ _) _ |- _ => inversion H; clear H; inv red
| H: multi_step red (Ref _) _ |- _ => inversion H; clear H; inv red
| H: multi_step red △ _ |- _ => inversion H; clear H; inv red
| H: red (Ref _) _ |- _ => inversion H; clear H; inv red
| H: red (_ @ _) _ |- _ => inversion H; clear H; inv red
| H: red △ _ |- _ => inversion H; clear H; inv red
| H: multi_step red _ (Ref _) |- _ => inversion H; clear H; inv red
| H: multi_step red _ (_ @ _) |- _ => inversion H; clear H; inv red
| H: multi_step red _ △ |- _ => inversion H; clear H; inv red
| H: red _ (Ref _) |- _ => inversion H; clear H; inv red
| H: red _ (_ @ _) |- _ => inversion H; clear H; inv red
| H: red _ △ |- _ => inversion H; clear H; inv red
| _ => subst; auto_t
 end.



(* t_red *) 

Definition t_red := multi_step t_red1. 

Lemma preserves_appl_t_red : preserves_appl t_red.
Proof. apply preserves_appl_multi_step. red; auto_t. Qed.

Lemma preserves_appr_t_red : preserves_appr t_red.
Proof. apply preserves_appr_multi_step. red; auto_t. Qed.

Lemma preserves_app_t_red : preserves_app t_red.
Proof. apply preserves_app_multi_step;  red; auto_t. Qed.

Ltac tree_red := 
intros; cbv; repeat (eapply succ_red ; [ auto 10 with *; fail|]); try eapply zero_red.

Lemma k_red2: forall M N, t_red (K@M@N) M.
Proof. tree_red.  Qed.

Lemma d_red : forall M N P,  t_red (D@M@N@P)  (N@P@(M@P)).
Proof. tree_red. Qed. 



Ltac zerotac := try apply zero_red; auto.
Ltac succtac :=
  repeat (eapply transitive_red;
  [ eapply succ_red ; auto_t; 
    match goal with
    | |- multi_step t_red1 _ _ => idtac
    | _ => fail (*gone too far ! *)
    end
  | ])
.
Ltac aptac := eapply transitive_red; [ eapply preserves_app_t_red |].

Ltac trtac := unfold_op; unfold t_red; succtac; 
  match goal with
  | |- multi_step t_red1 △ _ => zerotac
  | |- multi_step t_red1 (△ @ _ @ _ @ _) _ =>
    eapply transitive_red;
    [ eapply preserves_app_t_red ;
      [ eapply preserves_app_t_red ;
        [ eapply preserves_app_t_red ; [| trtac ] (* reduce the argument of △ *) 
        | ]
      | ]
     |] ;
    zerotac; (* put the "redex" back together *) 
    match goal with
    | |- multi_step t_red1 (△ @ ?arg @ _ @ _) _ =>
      match arg with
      | △  => trtac (* made progress so recurse *) 
      | △ @ _  => trtac (* made progress so recurse *) 
      | △ @ _ @ _ => trtac (* made progress so recurse *) 
      | _ => idtac (* no progress so stop *)
      end
    | _ => idtac (* for safety ? *) 
    end 
  | |- multi_step t_red1 (_ @ _) _ => (* not a ternary tree *) 
    eapply transitive_red; [ eapply preserves_app_t_red ; trtac |] ; (* so reduce the function *)
    match goal with
    | |- multi_step t_red1 (△ @ ?arg @ _ @ _) _ =>
      match arg with
      | △  => trtac (* made progress so recurse *) 
      | △ @ _  => trtac (* made progress so recurse *) 
      | △ @ _ @ _ => trtac (* made progress so recurse *) 
      | _ => idtac (* no progress so stop *)
      end
    | _ => idtac
    end
  | _ => idtac (* the head is not △ *) 
  end;
  zerotac; succtac; zerotac. 
                                        
Ltac ap2tac:=
  unfold t_red; 
  eassumption || 
              match goal with
              | |- multi_step _ (_ @ _) _ => try aptac; [ap2tac | ap2tac | ]
              | _ => idtac
              end. 


(* 3.4: Programs *)



Inductive program : Tree -> Prop :=
| pr_leaf : program △
| pr_stem : forall M, program M -> program (△ @ M)
| pr_fork : forall M N, program M -> program N -> program (△ @ M@ N)
.

Ltac program_tac := cbv; repeat (apply pr_stem || apply pr_fork || apply pr_leaf); auto.




(* 3.5: Propositional Logic *)

Definition conjunction := d (K@KI).
Definition disjunction := d (K@K) @I.
Definition implies := d (K@K). 
Definition negation := d (K@K) @ (d (K@KI) @ I).
Definition bi_implies := △@ (△@ I @ negation)@△.


Lemma conjunction_true : forall y, t_red (conjunction @ K @ y) y.
Proof.  tree_red. Qed. 
 
Lemma conjunction_false: forall y, t_red (conjunction @ KI @ y) KI.
Proof.  tree_red. Qed. 

Lemma disjunction_true : forall y, t_red (disjunction @ K @y) K.
Proof.  tree_red. Qed. 
 
Lemma disjunction_false: forall y, t_red (disjunction @ (K@I) @y) y. 
Proof.  tree_red. Qed.  

Lemma implies_true : forall y, t_red (implies @ K @ y) y. 
Proof.  tree_red. Qed.  

Lemma implies_false: forall y, t_red (implies @ (K@I) @ y) K.
Proof.  tree_red. Qed.  

Lemma negation_true : t_red (negation @ K) KI.
Proof.  tree_red. Qed.  

Lemma negation_false : t_red (negation @ KI) K.
Proof.  tree_red. Qed. 

Lemma iff_true : forall y, t_red (bi_implies @K@y) y. 
Proof.  tree_red. Qed. 

Lemma iff_false_true : t_red (bi_implies @ KI @K) KI.
Proof.  tree_red. Qed. 

Lemma iff_false_false : t_red (bi_implies @ KI @ KI) K. 
Proof.  tree_red. Qed. 


(* 3.6: Pairs *) 

Definition Pair := △ .
Definition first p :=  △@ p@ △@ K.
Definition second p := △ @p@ △@ KI.


Lemma first_pair : forall x y, t_red (first (Pair @x@y)) x. 
Proof.  tree_red. Qed.  

Lemma second_pair : forall x y, t_red (second (Pair @x@y)) y .
Proof.  tree_red. Qed.  

Definition first0 := △@ (△@ (K@K)) @ (△@ (△@ (K@ △))@ △).
Definition second0 := △@ (△@ (K@KI)) @ (△@ (△@ (K@ △))@ △).

Lemma first0_first: forall p,  t_red (first0 @ p) (first p).
Proof.  tree_red. Qed. 

Lemma second0_second: forall p, t_red (second0 @ p) (second p).
Proof.  tree_red. Qed. 

  
(* 3.7: Natural Numbers *)

Definition zero := △. 
Definition successor := K. 

Definition isZero := d (K@ (K@ (K@ KI))) @ (d (K@ K) @ △).

Definition predecessor := d (K@ KI) @ (d (K@ △) @  △).



Lemma isZero_zero : t_red (isZero @ △) K. 
Proof.  tree_red. Qed.  

Lemma isZero_successor : forall n, t_red (isZero @ (K@ n)) KI. 
Proof.  tree_red. Qed.  

Lemma predecessor_zero: t_red (predecessor @ △) △. 
Proof.  tree_red. Qed.  

Lemma predecessor_successor : forall n, t_red (predecessor @ (K@ n)) n.
Proof.  tree_red. Qed.


(* 3.8: Fundamental Queries *)

Definition query is0 is1 is2 :=
  d (K@is1)
   @(d (K@KI)
      @(d (K@ (K@ (K@(K@(K@ is2)))))
         @(d (K@(K@(K@ is0)))@△))).


Lemma query_eq_0:
  forall is0 is1 is2, t_red (query is0 is1 is2 @  △) is0.
Proof.   tree_red. Qed. 

Lemma query_eq_1: 
  forall is0 is1 is2 P,  t_red (query is0 is1 is2 @ (△ @ P)) (is0 @ KI @ is1).
Proof. tree_red.  Qed. 

Lemma query_eq_2:
  forall is0 is1 is2 P Q,  t_red (query is0 is1 is2 @ (△@ P@ Q)) is2. 
Proof. tree_red. Qed. 


Definition isLeaf := query K (K @ I) (K @ I).
Definition isStem := query (K @ I) K KI.
Definition isFork := query KI KI K.

Ltac unfold_op ::= unfold isLeaf, isStem, isFork, query, Sop, D, KI, I, K.


(* Chapter 4: Extensional Programs *)


(* 4.2: Combinations versus Terms *)

Inductive combination : Tree -> Prop :=
| is_Node : combination △
| is_App : forall M N, combination M -> combination N -> combination (M@ N)
.
Hint Constructors combination: TreeHintDb.

Ltac combination_tac := repeat (apply is_App || apply is_Node); auto. 

Lemma programs_are_combinations: forall M, program M -> combination M.
Proof.
  induction M; intro pr; inv1 program; subst; auto_t;
    apply is_App; [apply IHM1; apply pr_stem | apply IHM2]; auto.
Qed. 

(* 4.3: Variable Binding *)


Fixpoint substitute M x N :=
  match M with
  | Ref y => if eqb x y then N else Ref y
  | △ => △
  | M1 @ M2 => (substitute M1 x N) @ (substitute M2 x N)
end. 

Lemma substitute_app:
  forall M1 M2 x N, substitute (M1@ M2) x N = (substitute M1 x N) @ (substitute M2 x N). 
Proof. auto. Qed.

Lemma substitute_node:
  forall x N, substitute △ x N = △. 
Proof. auto. Qed.


Lemma substitute_combination: forall M x N, combination M -> substitute M x N = M.
Proof.
  induction M; intros ? ? c;  inversion c; subst; simpl; auto; rewrite IHM1; auto; rewrite IHM2; auto.
Qed. 

Lemma substitute_program: forall M x N, program M -> substitute M x N = M.
Proof. intros; apply substitute_combination; auto; apply programs_are_combinations; auto. Qed.

Hint Resolve substitute_combination substitute_program: TreeHintDb. 

Ltac subst_tac :=
  unfold_op;  repeat (unfold substitute; fold substitute;  unfold eqb, Ascii.eqb, Bool.eqb).

     
Lemma substitute_preserves_t_red:
    forall M x N N', t_red N N' -> t_red (substitute M x N) (substitute M x N').
Proof.
 induction M; intros; simpl; zerotac;
 [ match goal with |- t_red (if ?b then _ else _) _  =>  caseEq b; intros; zerotac; auto end |
 apply preserves_app_t_red; auto].
Qed.


(* Bracket Abstraction *)

  
Fixpoint bracket x M := 
match M with 
| Ref y =>  if eqb x y then I else (K@ (Ref y))
| △ => K@ △ 
| App M1 M2 => d (bracket x M2) @ (bracket x M1)
end
.

(* not used *) 
Theorem bracket_beta: forall M x N, t_red ((bracket x M) @ N) (substitute M x N).
Proof.
  induction M; intros; unfold d; simpl;  
  [ match goal with |- t_red ((if ?b then _ else _) @ _) _ => case b; tree_red end | 
  tree_red |
  unfold d; eapply succ_red;  auto_t; apply preserves_app_t_red; auto]. 
Qed.


(* star abstraction *)


Fixpoint occurs x M :=
  match M with
  | Ref y => eqb x y 
  | △ => false
  | M1@ M2 => (occurs x M1) || (occurs x M2)
  end.

Lemma occurs_combination: forall M x,  combination M -> occurs x M = false.
Proof. induction M; split_all; inv1 combination; subst; auto; rewrite IHM1; auto; rewrite IHM2; auto. Qed. 

Lemma occurs_ref: forall x y, occurs x (Ref y) = (x =? y).
Proof. auto. Qed. 

Lemma occurs_node: forall x, occurs x △ = false. 
Proof. auto. Qed. 

Lemma occurs_app: forall x M N, occurs x (M@ N) = occurs x M || occurs x N.
Proof. auto. Qed. 



Lemma substitute_occurs_false: forall M x N, occurs x M = false -> substitute M x N = M. 
Proof.
  induction M; simpl; intros x N e; split_all;
    [ rewrite e; auto | rewrite orb_false_iff in *; rewrite IHM1; try tauto; rewrite IHM2; tauto]. 
Qed.




Fixpoint star x M :=
  match M with
  | Ref y =>  if eqb x y then I else (K@ (Ref y))
  | △ => K@ △ 
  | App M1 (Ref y) => if eqb x y
                      then if occurs x M1
                           then d I @ (star x M1)
                           else M1
                      else  if occurs x M1
                           then d (K@ (Ref y)) @ (star x M1)
                            else K@ (M1 @ (Ref y))
  | App M1 M2 => if occurs x (M1 @ M2)
                 then d (star x M2) @ (star x M1)
                 else K@ (M1 @ M2)
  end. 

Notation "\" := star : tree_scope.

Lemma star_combination: forall M x, combination M -> \x M = K@ M. 
Proof.
  induction M as [ | | M1 M2 M3]; intros x c; try (split_all; inv1 combination; subst; auto; fail);
    inversion c as [ | ? ? c1 c3]; inversion c3; subst; split_all; rewrite ! occurs_combination; split_all.  
Qed.


Lemma star_leaf: forall x, \x △ = K@ △.
Proof. auto. Qed.


Lemma star_id: forall x, \x (Ref x) = I.
Proof. intro; unfold star, occurs; rewrite eqb_refl; auto. Qed.

Lemma star_occurs_false: forall M x, occurs x M = false -> \x M = K@ M. 
Proof.
  induction M as [ s | | M1 ? M2]; simpl; intros x occ; rewrite ? occ; auto;
  rewrite orb_false_iff in occ; inversion occ as (occ1 & occ2); 
  caseEq M2; [intros s e; subst; simpl in *; rewrite occ2; rewrite occ1 | |]; split_all.  
Qed.


Lemma eta_red: forall M x, occurs x M = false -> \x (M@ (Ref x)) = M.
Proof.  intros M x occ; unfold star at 1; fold star; rewrite eqb_refl; rewrite occ; auto. Qed.

Lemma star_occurs_true:
  forall M1 M2 x, occurs x (M1@ M2) = true -> M2 <> Ref x -> \x (M1@ M2) = △@ (△@ (\x M2))@ (\x M1).
Proof.
  intros M1 M2 x occ d; unfold star at 1; fold star.
  generalize occ d; clear occ d; caseEq M2; split_all. 
  (* 3 *)
  match goal with H : Ref ?s <> Ref x |- _ =>
                  assert(d2: eqb x s = false) by (apply eqb_neq; auto; congruence) end; 
  simpl in *; rewrite d2 in *;  rewrite orb_false_r in *.
  all: rewrite occ; auto. 
Qed.

Lemma star_occurs_twice:
  forall M1 x, occurs x M1 = true ->  \x (M1@ (Ref x)) = △@ (△@ I)@ (\x M1).
Proof. intros M1 x occ; unfold star at 1; fold star; rewrite eqb_refl; rewrite occ; auto. Qed.


Lemma occurs_substitute_true:
  forall M x y N, x<> y -> occurs x M = true -> occurs x (substitute M y N) = true.
Proof.     
  induction M; intros x y N d occ; simpl in *; auto; 
    [
      match goal with H : (x=? ?s) = true |- _ =>
                  assert(x=s) by (apply eqb_eq; auto);
                    assert(d2: eqb y s = false) by (apply eqb_neq;  split_all);
                    rewrite d2; simpl; auto end
  |
  rewrite orb_true_iff in occ; inversion occ; 
  [ rewrite IHM1; auto | rewrite IHM2; auto; apply orb_true_r]
    ].
Qed.

Ltac occurstac :=
  unfold_op; unfold occurs; fold occurs; rewrite ? orb_true_r;
  rewrite ? occurs_combination; auto; cbv; auto 1000 with *; fail. 

Ltac startac_true x :=
  rewrite (star_occurs_true _ _ x);
  [| occurstac | ( (intro; subst; inv1 combination; fail) || (cbv; discriminate)) ]. 

Ltac startac_twice x := rewrite (star_occurs_twice _ x); [| occurstac ]. 

Ltac startac_false x :=  rewrite (star_occurs_false _ x); [ | occurstac].

Ltac startac_eta x := rewrite eta_red; [| occurstac ].
  
Ltac startac x :=
  repeat (startac_false x || startac_true x || startac_twice x || startac_eta x || rewrite star_id).

Ltac starstac1 xs :=
  match xs with
  | nil => trtac
  | ?x :: ?xs1 => startac x; starstac1 xs1
  end.
Ltac starstac xs := repeat (starstac1 xs).


 
Theorem star_beta: forall M x N, t_red ((\x M) @ N) (substitute M x N).
Proof.
  induction M as [s | | M1 ? M2]; intros x N; simpl;  auto; 
  [ caseEq (x=?s); intros; tree_red 
  | tree_red
  | unfold d; caseEq M2; 
  [  intros s; split_all; subst;   caseEq (x=?s); intro e; unfold substitute; fold substitute; rewrite ? e; 
    [
      caseEq (occurs x M1); intros; trtac;
      [aptac; [ eapply IHM1 | |] | rewrite substitute_occurs_false; auto]; zerotac
    | 
    caseEq (occurs x M1); intros; trtac;
    [aptac; [ eapply IHM1 | |] | rewrite substitute_occurs_false; auto] ; zerotac
    ]
|
  simpl; rewrite orb_false_r; 
  caseEq (occurs x M1); intros; trtac;
    [ aptac; [ eapply IHM1 | |] | rewrite substitute_occurs_false; auto]; zerotac
  |
    intros t t0 e; subst; simpl;    caseEq (occurs x M1  || (occurs x t || occurs x t0)); intros; trtac; 
    [
      aptac; [ eapply IHM1 | eapply IHM2 |] |
      rewrite ! orb_false_iff in *; rewrite ! substitute_occurs_false];
    zerotac;  tauto
  ]].
Qed.



(* 4.4: Fixpoints *) 


Definition ω := Eval cbv in \"w" (\"f" ((Ref "f")@ ((Ref "w")@ (Ref "w")@ (Ref "f")))).
Definition Y := ω @ ω. 


Lemma y_red: forall f, t_red (Y@f) (f@ (Y@f)).
Proof. intros; unfold Y at 1; unfold ω at 1; trtac; auto. Qed. 


(* 4.5 Waiting *)


Definition W_0 := \"x" (\"y" (\"z" ((Ref "x") @ (Ref "y") @ (Ref "z")))).
Definition W := \"x" (\"y" (bracket "z" ((Ref "x") @ (Ref "y") @ (Ref "z")))).


Definition wait M N := d I @ (d (K@ N) @ (K@ M)).
Definition wait1 M :=
  d
    (d (K @ (K @ M))
       @ (d (d K @ (K @ △)) @ (K @ △))
    )
    @ (K @ (d (△ @ K @ K))).

Lemma wait_red: forall M N P, t_red ((wait M N) @ P) (M@N@P).
Proof. tree_red. Qed. 

Lemma wait1_red: forall M N, t_red ((wait1 M) @ N) (wait M N). 
Proof. tree_red. Qed. 

Lemma w_red1 : forall M, t_red (W@M) (wait1 M).
Proof.   tree_red. Qed.    

Lemma w_red2 : forall M N, t_red (W@M@N) (wait M N).
Proof.   tree_red. Qed.    

Lemma w_red : forall M N P, t_red (W@M@N@P) (M@N@P).
Proof.  tree_red. Qed. 


(* 4.6: Fixpoint Functions *)


Definition self_apply := Eval cbv in \"x" (Ref "x" @ (Ref "x")).

Definition Z f := wait self_apply (d (wait1 self_apply) @ (K@f)). 


Lemma Z_program: forall f, program f -> program (Z f). 
Proof. intros; program_tac. Qed.


Lemma Z_red : forall f x, t_red (Z f @ x) (f@ (Z f) @ x).
Proof. tree_red. Qed. 

Definition swap f := d (K @ f) @ (d (d K @ (K @ △)) @ (K @ △)).

Lemma swap_red: forall f x y, t_red (swap f @ x @ y) (f @ y @ x).
Proof. tree_red. Qed.

Definition Y2 f := Z (swap f).

Theorem fixpoint_function : forall f x, t_red (Y2 f @ x) (f @ x @ Y2 f).
Proof. tree_red. Qed. 

Definition Y2_red := fixpoint_function.

Lemma Y2_program : forall f, program f -> program (Y2 f).
Proof. intros; program_tac. Qed. 



(* 4.7: Arithmetic *)

Definition plus_aux :=
  Eval cbv in  (\"m"
           (\"p"
                 (△@ (Ref "m") @ I @
                   (K@ (\"m1" (\"n" (K@ ((Ref "p") @ (Ref "m1") @ (Ref "n"))))))
               ))).
Definition plus := Y2 plus_aux. 

Lemma plus_zero: forall n, t_red (plus @ zero @ n) n. 
Proof. tree_red. Qed.

Lemma plus_successor:
  forall m n,  t_red (plus @ (successor @ m) @ n) (successor @ (plus @ m@ n)). 
Proof. 
  intros; unfold plus at 1; aptac; [  apply Y2_red | trtac | unfold plus_aux, successor; trtac]. 
Qed.

Definition times_aux :=
  Eval cbv in
    \"m"
     (\"times"
       (\"n"
         (App (App (△@ (Ref "n")) △)
              (K@ (\"x" (App (App (Ref "plus") (Ref "m"))
                             (App (App (Ref "times") (Ref "m")) (Ref "x")))))
     ))).

Print times_aux.

Definition times := Y2 (
                        △ @
(△ @
 (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
  (△ @
   (△ @
    (△ @
     (△ @
      (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @
            (△ @
             (△ @
              (△ @
               (△ @
                (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @
                 (△ @
                  (△ @
                   (△ @
                    (△ @
                     (△ @
                      (△ @
                       (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                        (△ @
                         (△ @
                          (△ @
                           (△ @
                            (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                             (△ @
                              (△ @
                               (△ @
                                (△ @
                                 (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                                  (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                                (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ 
                         (△ @ △ @ △)))) @
                      (△ @
                       (△ @
                        (△ @
                         (△ @
                          (△ @ (△ @ (△ @ (△ @ plus) @ (△ @ △ @ (△ @ △)))) @
                           (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
                    (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
          (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
(△ @ △ @ (△ @ (△ @ (△ @ △ @ (△ @ (△ @ (△ @ △ @ △)) @ △)))))
).

Lemma times_zero: forall m, t_red (times @ m @ zero) zero.
Proof. tree_red. Qed.


Lemma times_successor:
  forall m n,  t_red (times @ m @ (successor @ n)) (plus @ m @ (times @ m @ n)). 
Proof.   intros; unfold times at 1; aptac. apply Y2_red. trtac. unfold successor; trtac. Qed. 

(* 6 *)

Definition minus := 
  Y2 (\"m"
           (\"minus"
                 (\"n"
                       (App (App (△@ (Ref "n")) (Ref "m"))
                            (K@ (App (Ref "minus") (App predecessor (Ref "m")))))
                  ))).


(* 4.8: Lists and Strings *)


Definition t_nil := △. 
Definition t_cons h t := △@ h@ t.
Definition t_head := \"xs" (△@ (Ref "xs") @ (K@ I) @ K).
Definition t_tail := \"xs" (△@ (Ref "xs") @ (K@ I) @ (K@ I)).

Lemma head_red: forall h t, t_red (t_head @ (t_cons h t)) h.
Proof. tree_red. Qed. 
Lemma tail_red: forall h t, t_red (t_tail @ (t_cons h t)) t.
Proof. tree_red. Qed. 

(* 4.9: Mapping and Folding *)

Definition swap_comb := Eval cbv in \"f" (swap (Ref "f")).

Lemma swap_comb_red: forall f, t_red (swap_comb @ f) (swap f). 
Proof. tree_red. Qed.


Definition list_map_swap_aux :=
  (* the list argument xs then the recursion argument map and finally the function f, to  exploit Y2 *) 
  Eval cbv in
    \"xs"
     (Node @ Ref "xs"
           @ (K @ (K @ t_nil))
           @ (\"h"
               (\"t"
                 (\"map"
                   (\"f"
                     (t_cons
                        (Ref "f" @ Ref "h") 
                        (Ref "swap" @ (Ref "map") @ Ref "f" @ Ref "t")
          )))))).

Set Printing Depth 1000.
Print list_map_swap_aux.

Definition list_map_swap := (Y2 (△ @
(△ @
 (△ @ △ @
  (△ @
   (△ @
    (△ @
     (△ @
      (△ @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @
            (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
             (△ @
              (△ @
               (△ @
                (△ @
                 (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                  (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
                (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ 
       (△ @ △ @ △))) @ (△ @ △ @ (△ @ △)))) @
   (△ @ △ @
    (△ @
     (△ @
      (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
            (△ @
             (△ @
              (△ @
               (△ @
                (△ @
                 (△ @
                  (△ @ (△ @ (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △))) @
                   (△ @ △ @ (△ @ △)))) @ (△ @ △ @ (△ @ (△ @ swap_comb))))) @ 
               (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △))))))))) @
(△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ △)))) @ △)
                            )).

Definition list_map := swap list_map_swap. 

Lemma map_nil: forall f, t_red(list_map @ f @ t_nil) t_nil.
Proof.  tree_red. Qed. 

Lemma map_cons :
  forall f h t, t_red (list_map @ f @ (t_cons h t)) (t_cons (f @ h) (list_map @ f@ t)).
Proof. 
  intros; unfold list_map at 1. eapply transitive_red. apply swap_red.  aptac.
  unfold list_map_swap. apply Y2_red. zerotac. fold list_map_swap. 
  trtac. unfold t_cons. trtac. aptac. zerotac. aptac. aptac. apply swap_comb_red. all: zerotac.
Qed.


Definition swap3 := Eval cbv in \"fold" (\"f" (\"x" (\"ys" (Ref "fold" @ Ref "ys" @ Ref "f" @ Ref "x")))).

Lemma swap3_red : forall g f x y, t_red (swap3 @ g @ f @ x @ y) (g @ y @ f @ x).
Proof. tree_red. Qed. 

Definition list_foldleft_aux := 
  Eval cbv in
    \"ys"
     ( Node @ Ref "ys" @ (K @ (K @ I))
            @ (\"h"
                (\"t"
                  (\"fold" 
                    (\"f"
                      (\"x"
                        (Ref "swap3" @ Ref "fold" @ Ref "f" @ (Ref "f" @ Ref "h" @ Ref "x") @ Ref "t")
     )))))).

Print list_foldleft_aux.

Definition list_foldleft_swap := Y2 (
                                     △ @
(△ @
 (△ @ △ @
  (△ @
   (△ @
    (△ @ △ @
     (△ @
      (△ @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @ (△ @ (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △))) @ (△ @ △ @ (△ @ △)))) @
          (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
   (△ @
    (△ @
     (△ @
      (△ @
       (△ @
        (△ @
         (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
          (△ @
           (△ @
            (△ @
             (△ @
              (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
               (△ @
                (△ @
                 (△ @
                  (△ @
                   (△ @
                    (△ @
                     (△ @ △ @
                      (△ @
                       (△ @
                        (△ @
                         (△ @
                          (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @
                           (△ @ (△ @ (△ @ (△ @ swap3) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                         (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                    (△ @
                     (△ @
                      (△ @
                       (△ @
                        (△ @
                         (△ @
                          (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                           (△ @
                            (△ @
                             (△ @
                              (△ @
                               (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                                (△ @
                                 (△ @
                                  (△ @
                                   (△ @
                                    (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                                     (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                                   (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ 
                            (△ @ △ @ △)))) @ (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ 
                     (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ 
           (△ @ △ @ △)))) @ (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △))))) @
(△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))))) @ △)
). 

Definition list_foldleft := swap3 @ list_foldleft_swap. 

Lemma list_foldleft_nil:
  forall f x, t_red (list_foldleft @ f @ x @ t_nil) x. 
Proof. tree_red. Qed. 

Lemma list_foldleft_cons:
  forall f x h t, t_red (list_foldleft @ f @ x @ (t_cons h t)) (list_foldleft @ f @ (f @ h @ x) @ t). 
Proof.
  intros; unfold list_foldleft at 1. eapply transitive_red. apply swap3_red.
    unfold list_foldleft_swap. aptac. aptac. apply Y2_red. zerotac. fold list_foldleft_swap. 
    unfold list_foldleft_aux.   trtac. zerotac. unfold t_cons. trtac. 
Qed.


Definition list_foldright_aux := 
  Eval cbv in
    \"ys"
     (Node @ Ref "ys" @ (K @ (K @ I))
           @ (\"h"
                (\"t"
                  (\"fold" 
                    (\"f"
                      (\"x"
                        (Ref "f" @ Ref "h" @ (Ref "swap3" @ Ref "fold" @ Ref "f" @ Ref "x" @ Ref "t" ))
     )))))).


Print list_foldright_aux.

Definition list_foldright_swap := Y2 (
                                      △ @
(△ @
 (△ @ △ @
  (△ @
   (△ @
    (△ @ △ @
     (△ @
      (△ @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
            (△ @
             (△ @
              (△ @
               (△ @
                (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                 (△ @
                  (△ @
                   (△ @
                    (△ @
                     (△ @
                      (△ @
                       (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                        (△ @
                         (△ @
                          (△ @
                           (△ @
                            (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
                             (△ @
                              (△ @
                               (△ @
                                (△ @
                                 (△ @
                                  (△ @
                                   (△ @ △ @
                                    (△ @ (△ @ (△ @ (△ @ swap3) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                                  (△ @
                                   (△ @
                                    (△ @
                                     (△ @
                                      (△ @
                                       (△ @
                                        (△ @
                                         (△ @ (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △))) @
                                         (△ @ △ @ (△ @ △)))) @ (△ @ △ @ (△ @ △)))) @ 
                                     (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ 
                              (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                      (△ @ △ @ (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))))))) @ (△ @ △ @ △))) @ 
                  (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
          (△ @ △ @ (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))))))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
   (△ @
    (△ @
     (△ @
      (△ @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @
            (△ @
             (△ @
              (△ @
               (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @
                (△ @
                 (△ @
                  (△ @
                   (△ @
                    (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                     (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
                   (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △))) @ 
          (△ @ △ @ (△ @ △)))) @ (△ @ △ @ (△ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △))))) @
(△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))))) @ △)
                                    ).

Definition list_foldright := swap3 @ list_foldright_swap. 

Lemma list_foldright_nil:  forall f x, t_red (list_foldright @ f @ x@ t_nil) x. 
Proof. tree_red. Qed. 

Lemma list_foldright_cons:
  forall f x h t, t_red (list_foldright @ f @ x @ (t_cons h t)) (f @ h @ (list_foldright @ f@ x @ t)). 
Proof.
  intros; unfold list_foldright at 1. eapply transitive_red. apply swap3_red.
    unfold list_foldright_swap. aptac. aptac. apply Y2_red. zerotac. fold list_foldright_swap. 
    unfold list_foldright_aux.   trtac. zerotac. unfold t_cons. trtac. 
Qed. 


Definition list_append xs ys :=
  list_foldright @ (\"h" (\"t" (t_cons (Ref "h") (Ref "t")))) @ ys @ xs.


Lemma append_nil_r: forall xs, t_red (list_append t_nil xs) xs.
Proof. apply list_foldright_nil. Qed.



(* Chapter 5: Intensional Programs *) 

(* 5.1: Size *)


Definition size_aux :=
  Eval cbv in 
    \"x"
       (isStem
             @ (Ref "x")
             @ (\"s"
                 (△
                  @ (Ref "x" @ △)
                  @ zero
                  @ (\"x1" (K @ (successor @ ((Ref "s") @ (Ref "x1")))))
               ))
             @ (△
                  @ (Ref "x")
                  @ (K @ (successor @ zero))
                  @ (\"x1"
                       (\"x2"
                          (\"s"
                            (successor
                               @ (Ref "plus"
                                      @ ((Ref "s") @ (Ref "x1"))
                                      @ ((Ref "s") @ (Ref "x2"))
       ))))))).

Set Printing Depth 1000.
Print size_aux.


Definition size := Y2 (△ @
(△ @
 (△ @
  (△ @
   (△ @ △ @
    (△ @
     (△ @
      (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @ (△ @ (△ @ △ @ (△ @ △ @ △))) @
            (△ @
             (△ @
              (△ @
               (△ @
                (△ @
                 (△ @
                  (△ @ △ @
                   (△ @
                    (△ @
                     (△ @
                      (△ @
                       (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                        (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
                      (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                 (△ @
                  (△ @
                   (△ @
                    (△ @
                     (△ @
                      (△ @
                       (△ @ (△ @ (△ @ △ @ (△ @ △ @ plus))) @
                        (△ @
                         (△ @
                          (△ @
                           (△ @
                            (△ @ (△ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △)))) @
                             (△ @ (△ @ (△ @ (△ @ (△ @ △)) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @
                           (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ (△ @ △)))) @ 
                    (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ △))) @ (△ @ △ @ △)))) @ 
          (△ @ △ @ △))) @ (△ @ △ @ △)))) @ (△ @ △ @ (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △))))))))) @
  (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ △)))) @ △))) @
(△ @
 (△ @
  (△ @
   (△ @
    (△ @
     (△ @
      (△ @ (△ @ (△ @ △ @ △)) @
       (△ @ (△ @ (△ @ (△ @ (△ @ △ @ △)) @ (△ @ (△ @ △) @ (△ @ △)))) @ (△ @ △ @ △)))) @
     (△ @ △ @ (△ @ △)))) @
   (△ @ △ @
    (△ @
     (△ @
      (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @
       (△ @
        (△ @
         (△ @ (△ @ (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △)))) @ (△ @ (△ @ △) @ (△ @ △ @ △)))) @
          (△ @ △ @ △))) @ (△ @ △ @ △)))))))) @
 (△ @ (△ @ (△ @ △ @ (△ @ △))) @
  (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △))))) @
   (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △))))))))) @
    (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ (△ @ (△ @ △) @ (△ @ △))))))) @ △)))))
                      ).


Lemma size_program: program size.
Proof. cbv; program_tac. Qed. 

Lemma size_leaf: t_red (size @ △) (successor @ zero).
Proof. tree_red. Qed. 

Lemma size_fork:
  forall M N, t_red (size @ (△@ M@N)) (successor @(plus @ (size @ M) @ (size @ N))).
Proof. intros;  unfold size; eapply transitive_red; [apply Y2_red | trtac]. Qed.


Lemma size_stem: forall M, t_red (size @ (△@ M)) (successor @ (size @ M)).
Proof. intros;  unfold size; eapply transitive_red; [apply Y2_red | trtac]. Qed.



(* 5.2: Equality *)


Definition equal_aux := 
  Eval cbv in 
    \"x"
     (isStem
        @ (Ref "x")
        @ (\"e" (\"y" (isStem
                         @ (Ref "y")
                         @ ((Ref "e")
                              @ (△ @ ((Ref "x") @ △) @ △ @ K)
                              @ (△ @ ((Ref "y") @ △) @ △ @ K)
                           )
                         @ KI
                      )))
        @ (△
             @ (Ref "x")
             @ (\"e" (\"y" (isLeaf @ (Ref "y"))))
             @ (\"x1"
                 (\"x2"
                   (\"e"
                     (\"y" (isFork
                              @ (Ref "y")
                              @ (△
                                   @ (Ref "y")
                                   @ △
                                   @ (\"y1"
                                       (\"y2"
                                         ((Ref "e")
                                            @ (Ref "x1")
                                            @ (Ref "y1")
                                            @ ((Ref "e")
                                                 @ (Ref "x2")
                                                 @ (Ref "y2")
                                              )
                                            @ KI
                                ))))
                              @ KI
     ))))))).

Definition equal := Y2 equal_aux.

(* Compute (term_size equal). 1145 *) 

Lemma equal_program: program equal.
Proof. program_tac. Qed.

Ltac equaltac :=
  aptac; [ unfold equal; apply Y2_red | zerotac | fold equal; unfold equal_aux; trtac].


Theorem equal_programs: forall M,  program M -> t_red (equal @ M @ M) K.
Proof.
  intros M prM; induction prM; intros; equaltac;
  aptac; [ aptac; [ apply IHprM1 | apply IHprM2 | zerotac] | zerotac |  trtac].
Qed.

Theorem unequal_programs:
  forall M,  program M -> forall N, program N -> M<> N -> t_red (equal @ M @ N) KI. 
Proof.
  intros M prM; induction prM; intros P prP neq; inversion prP; intros; subst;
    try congruence; equaltac. (* slow *) 
  apply IHprM; congruence.
  assert(d: M = M0 \/ M<> M0) by repeat decide equality;   inversion d; subst.
  aptac. aptac. apply  equal_programs; auto. apply  IHprM2;    congruence.  zerotac. zerotac. trtac.
  aptac. aptac. apply IHprM1;    congruence.  zerotac. zerotac. trtac. trtac. 
Qed.


(* 5.3: Tagging *)
  


Definition tag t f := Eval cbv in d t @ (d f @ (K@ K)).
Definition getTag := Eval cbv in \"p" (first ((first (Ref "p")) @ △)).
Definition untag := Eval cbv in \"x" (first ((first (second (Ref "x"))) @ △)). 

Lemma tag_apply : forall t f x, t_red (tag t f @ x) (f@x).
Proof.  tree_red. Qed. 

Lemma getTag_tag : forall t f, t_red (getTag @ (tag t f)) t .
Proof.  tree_red. Qed. 

Lemma untag_tag: forall t f, t_red (untag @ (tag t f)) f. 
Proof.  tree_red. Qed. 


Theorem tree_calculus_support_tagging :
  exists tag getTag, (forall t f x, t_red (tag t f @ x) (f@ x)) /\
                      (forall t f,  t_red (getTag @ (tag t f)) t).
Proof. exists tag, getTag; split_all; tree_red. Qed. 


Definition tag_wait t :=
  Eval cbv in
    substitute (\"g" (tag (Ref "t") (wait self_apply (Ref "g")))) "t" t.


Definition Y2_t t f := tag t (wait self_apply (d (tag_wait t) @ (K@ (swap f)))). 


Lemma Y2_t_program: forall t f, program t -> program f -> program (Y2_t t f). 
Proof. intros; program_tac. Qed.


Theorem Y2_t_red : forall t f x, t_red(Y2_t t f @ x) (f@ x @ (Y2_t t f)).
Proof. tree_red. Qed. 

Theorem getTag_Y2_t: forall t f, t_red (getTag @ (Y2_t t f)) t.
Proof. tree_red.  Qed. 

(* More Queries *)

Definition isStem2 := \"a" (△ @ (Ref "a") @ △ @ (K@(K@ △))).



Definition isFork2 :=  (* maps forks to a leaf and others to a fork *) 
  \"z" (△ @ (Ref "z") @ (K@K) @ (K@(K@ △))).

Lemma isFork2_leaf: t_red (isFork2 @ △) (K@K).
Proof. tree_red. Qed.

Lemma isFork2_stem: forall x, t_red(isFork2 @ (△@x)) (K@(x@(K@(K@△)))).
Proof. tree_red.  Qed.


Lemma isFork2_fork: forall x y, t_red(isFork2 @ (△@ x@ y)) △. 
Proof. tree_red. Qed. 


(* 5.5: Triage *)


Definition triage f0 f1 f2  :=
  (* 
  star
    "a"
    (△ 
       @ (isStem2 @ (Ref "a"))
       @ (△ @ (Ref "a") @ (Ref "f0") @ (Ref "f2"))
       @ (K@(K@ (△ @ (Ref "a" @ △) @ △ @ (\"x" ((K @ ((Ref "f1") @ (Ref "x"))))))))
    ).
   *)
  △ @
       (△ @
        (△ @
         (△ @
          (△ @
           (△ @
            (△ @ (△ @ (△ @ △ @ (△ @ (△ @ f1) @ (△ @ △ @ (△ @ △))))) @
             (△ @ (△ @ (△ @ △ @ △)) @
              (△ @ (△ @ (△ @ (△ @ (△ @ △ @ △)) @ (△ @ (△ @ △) @ (△ @ △)))) @ (△ @ △ @ △))))) @
           (△ @ △ @ (△ @ △)))) @ (△ @ △ @ (△ @ △)))) @
       (△ @ (△ @ (△ @ (△ @ (△ @ △ @ f2)) @ (△ @ (△ @ (△ @ △ @ f0)) @ △))) @
        (△ @ (△ @ (△ @ (△ @ (△ @ △ @ (△ @ △ @ (△ @ △ @ △)))) @ (△ @ (△ @ (△ @ △ @ △)) @ △))) @
         (△ @ △ @ △))). 


Lemma triage_leaf: forall M0 M1 M2, t_red (triage M0 M1 M2 @ △) M0.
  Proof. tree_red. Qed. 

Lemma triage_stem: forall M0 M1 M2 P, t_red (triage M0 M1 M2 @ (△@ P)) (M1 @ P).
Proof. tree_red. Qed. 

Lemma triage_fork: forall M0 M1 M2 P Q, t_red(triage M0 M1 M2 @ (△@ P@Q)) (M2 @ P @Q).
Proof. tree_red. Qed.




(* Section 5.8: Pattern matching  *) 




Definition leaf_case s :=
  Eval cbv in 
    substitute (\"r" (\"x" (isLeaf @ (Ref "x") @ (Ref "s") @ ((Ref "r" @ (Ref "x")))))) "s" s.


Definition stem_case f :=
  Eval cbv in 
    substitute
      (\"r"
         (\"x"
            (isStem
               @ (Ref "x") 
               @ (△
                    @ ((Ref "x") @△)
                    @ △
                    @ (\"y"
                         (K@
                           (Ref "f" 
                              @ (\"z" ((Ref "r") @ (△ @ (Ref "z"))))
                              @ (Ref "y")
                 )))) 
               @ ((Ref "r") @ (Ref "x"))
      )))
      "f" f.


Definition fork_case_r1 :=
    Eval cbv in 
    \"x1" (\"x2" (\"r1" (Ref "r1" @ (△ @ (Ref "x1") @ (Ref "x2"))))). 

Definition fork_case_r2 p1 :=
    Eval cbv in 
    substitute (\"x2" (\"r2" ((Ref "r2") @(△ @ Ref "p1" @ (Ref "x2"))))) "p1" p1.



Definition fork_case f :=
  Eval cbv in 
    substitute
      (\"r"
         (\"x"
             (isFork
                @ (Ref "x")
                @ (△
                     @ (Ref "x")
                     @△
                     @ (\"x1"
                          (\"x2"
                             (wait (Ref "f") fork_case_r1
                                   @ (Ref "x1")
                                   @ (Ref "x2")
                                   @ (Ref "r") 
                  ))))
                @ ((Ref "r") @ (Ref "x"))
      )))
      "f" f.



Fixpoint tree_case p s :=
  match p with
  | Ref x => K@ (\x s)
  | △ => leaf_case s
  | △@ p => stem_case (tree_case p s)
  | △@ p @ q => fork_case (tree_case p (wait (tree_case q (K@s)) (fork_case_r2 p)))
  | _ => I
  end.
          


Definition extension p s r := wait (tree_case p s) r. 
     

Ltac extensiontac :=
  intros; unfold extension; fold extension;
  eapply transitive_red; [ apply wait_red
                         | unfold tree_case, leaf_case, stem_case, fork_case; trtac];
   unfold wait, d; starstac ("z" :: "y" :: "x" :: "r" :: nil); unfold d; subst_tac; trtac.

  
Lemma extension_leaf : forall s r, t_red (extension △ s r @ △) s.
Proof.  extensiontac.  Qed.

Lemma extension_leaf_stem :
  forall  s r u , t_red(extension △ s r @ (△@u)) (r@ (△@u)). 
Proof. extensiontac. Qed.

Lemma extension_leaf_fork: forall s r t u, t_red(extension △ s r @ (△@t@u)) (r@ (△@t@u)). 
Proof. extensiontac. Qed.

Lemma extension_stem_leaf: forall p s r, t_red(extension (△ @ p) s r @ △) (r @ △).
Proof. extensiontac. Qed. 

Lemma extension_stem: forall p s r u,
    exists t, t_red(extension (△ @ p) s r @ (△ @ u)) t /\ t_red (extension p s (△@ K @ (K@ r)) @ u) t. 
Proof.  intros; exists (tree_case p s @ (△ @ (△ @ △) @ (△ @ △ @ r)) @ u); split; extensiontac. Qed. 

Lemma extension_stem_fork: forall p s r t u,
    t_red (extension (△ @ p) s r @ (△ @ t @ u)) (r@ (△ @ t @ u)).
Proof. extensiontac.   Qed. 


Lemma extension_fork_leaf: forall p q s r, t_red(extension (△ @ p@q) s r @ △) (r @ △).
Proof. extensiontac.  Qed. 

Lemma extension_fork_stem: forall p q s r u,
    t_red (extension (△ @ p@q) s r @ (△ @ u)) (r@(△ @ u)).
Proof. extensiontac.  Qed. 


Lemma extension_fork: forall p q s r t u, exists Q, 
    t_red(extension (△ @ p@q) s r @ (△ @ t @ u)) Q /\ 
         t_red (extension p (extension q (K@ s) (fork_case_r2 p)) fork_case_r1 @ t @ u @ r) Q.
Proof.
  intros; unfold extension; fold extension.
  exists  (tree_case p (wait (tree_case q (△ @ △ @ s)) (fork_case_r2 p)) @ fork_case_r1 @ t @ u @ r). 
  split. eapply transitive_red. apply wait_red.
  unfold tree_case; fold tree_case; unfold fork_case; fold fork_case; trtac.
  aptac. aptac. apply wait_red. all: zerotac. 
Qed. 

(* eager evaluation *)



Inductive factorable: Tree -> Prop :=
| factorable_leaf : factorable △
| factorable_stem: forall M, factorable (△ @ M)
| factorable_fork: forall M N, factorable (△ @ M @ N)
.

Hint Constructors factorable :TreeHintDb. 



Lemma factorable_or_not: forall M,  factorable M \/ ~ (factorable M).
Proof.
  induction M; intros; auto_t.
  right; intro; inv1 factorable. 
  case M1; intros; auto_t.
  right; intro; inv1 factorable.
  case t; intros; auto_t;  right; intro; inv1 factorable.
Qed.


Lemma programs_are_factorable: forall p, program p -> factorable p.
Proof. intros p pr; inversion pr; auto_t. Qed. 

Definition eager := \"z" (\"f" (△ @ (Ref "z") @ I @ (K@KI) @ I @ (Ref "f") @ (Ref "z"))). 

Lemma eager_of_factorable : forall M N, factorable M -> t_red (eager @ M @ N)  (N @ M).
Proof.   intros M N fac; inversion fac; cbv; trtac. Qed.


 (* Chapter 6: Reflective Programs *)



(* Branch-first evaluation *)

Inductive branch_first_eval: Tree -> Tree -> Tree -> Prop :=
| e_leaf : forall x, branch_first_eval △ x (△ @ x)
| e_stem : forall x y, branch_first_eval (△ @ x) y (△ @ x @ y)
| e_fork_leaf: forall y z, branch_first_eval (△ @ △ @ y) z y
| e_fork_stem: forall x y z yz xz v,
    branch_first_eval y z yz -> branch_first_eval x z xz -> branch_first_eval yz xz v ->
    branch_first_eval (△ @ (△ @ x) @ y) z v
| e_fork_fork : forall w x y z zw v, branch_first_eval z w zw -> branch_first_eval zw x v ->
                                     branch_first_eval (△ @ (△ @ w @ x) @ y) z v
.
              
Hint Constructors branch_first_eval: TreeHintDb.

Lemma branch_first_program :
  forall M N P, branch_first_eval M N P -> program M -> program N -> program P.
Proof.  intros M N P ev; induction ev; intros; inv1 program; program_tac. Qed. 
  

Lemma branch_first_eval_program_red: forall M N, program (M@N) -> branch_first_eval M N (M@N).
Proof. intros M N p; inv1 program; auto_t. Qed.


    
Definition Db x := D @ (D @ (K @ x) @ I) @ (K @ D).


Definition bf_leaf := Eval cbv in \"y" (K @ (K @ (Ref "y"))).

Definition bf_fork :=
  Eval cbv in 
    \"wf"
      (\"xf"
         (K
            @ (d
                  (d K
                      @ (d (d (K @ Ref "wf")) @ (K@D))
                   )
                 @ (K @ (d (K @ Ref "xf")))
      ))). 


Definition bf_stem e  :=
  Eval cbv in 
    substitute
      (\"xs"
         (\"ys"
            (d (d (K@(K@ Ref "e")) @ (Db (Ref "xs")))
               @ (d (d K @ (Db (Ref "ys")))
                    @ (K @ D)
      ))))
      "e" e. 
      

Definition onFork tr :=
  Eval cbv in
    substitute
      (\"t"
         (△
            @ (isFork2 @ Ref "t")
            @ (△ @ (Ref "t") @ △ @ Ref "triage")
            @ (K @ (K @ (K@ Ref "t")))
      ))
      "triage" tr.


Definition bf :=  Y2 (onFork (triage bf_leaf (bf_stem eager) bf_fork)). 


Ltac bf_tac :=
  intros; unfold bf, Y2; eapply transitive_red; [apply Y2_red | unfold swap, onFork, d; trtac].

Lemma program_bf : program bf.
Proof. program_tac. Qed.


Lemma bf_leaf_red: t_red (bf @ △) △.  
Proof.  bf_tac. Qed.


Lemma bf_stem_red: forall x, t_red (bf @ (△ @ x)) (△ @ x).  
Proof. bf_tac. Qed.

Lemma bf_fork_red: forall x y, t_red (bf @ (△ @ x @ y))
                                 ((triage bf_leaf (bf_stem eager) bf_fork) @ x @ y @ bf).  
Proof. bf_tac. Qed.

         

Lemma bf_fork_leaf_red:  forall y z, t_red(bf @ (△@△@y) @ z) y.
Proof.
  intros; aptac; [apply bf_fork_red | zerotac |]; aptac; [ aptac; [aptac; [apply triage_leaf | |] | |] | |];
  zerotac; unfold bf_leaf; trtac.
Qed.



Lemma bf_fork_stem_red:
  forall x y z, t_red (bf @ (△@(△@x) @y) @ z) (eager @ (bf @ x @ z) @ (bf @ (bf @ y @ z))). 
Proof.
  intros; aptac; [ apply bf_fork_red | zerotac |]; aptac; [ aptac; [ aptac; [apply triage_stem | |] | |] | |];
    zerotac;  unfold bf_stem, Db; trtac. 
Qed.


Lemma bf_fork_fork_red:
  forall w x y z, t_red (bf @ (△@(△@w@x) @y) @ z) (bf @ (bf @ z @ w) @x).
Proof.
  intros; aptac; [apply bf_fork_red | zerotac |]; aptac; [ aptac; [ aptac; [apply triage_fork | |] | |] | |];
  zerotac; unfold bf_fork;  trtac.
Qed.



(* 
Compute (term_size bf). (* = %73 vs 621 vs 685 vs 957 vs 1390 in Rewriting *) 
 *)

Theorem branch_first_eval_to_bf:
  forall M N P, program M -> program N -> branch_first_eval M N P -> t_red(bf@M@N) P. 
Proof.
  intros M N P prM prN ev; induction ev; intros; subst; inv1 program; subst. 
    {aptac; [apply bf_leaf_red | |]; zerotac. }
    {aptac; [apply bf_stem_red | |]; zerotac. } 
    {apply bf_fork_leaf_red. }
  {
  eapply transitive_red. apply bf_fork_stem_red.
  aptac. aptac. zerotac. apply IHev2. all: zerotac.
  eapply transitive_red. apply eager_of_factorable.  apply programs_are_factorable.
  eapply branch_first_program; eauto.
  aptac.   aptac. zerotac. apply IHev1. all: zerotac.
  apply IHev3; eapply branch_first_program; eauto.
  }{
  eapply transitive_red. apply bf_fork_fork_red. 
  aptac. aptac. zerotac. apply IHev1. all: zerotac. apply IHev2; auto. 
  eapply branch_first_program; eauto.
  }
Qed.



(* Root Evaluation *)
(* This acts on quotations *) 

(* quotation *)

Fixpoint meta_quote M :=
 match M with
 | M1 @ M2 => △ @ (meta_quote M1) @ (meta_quote M2)
 | _ => M
 end.

Lemma meta_quote_app: forall M N, Node @ (meta_quote M) @ (meta_quote N) = meta_quote (M@N). 
Proof. split_all. Qed. 
       
Definition quote_aux :=
  Eval cbv in
    \"x"
       (\"q"
          (isStem
             @ (Ref "x")
             @ (△ @ ((Ref "x") @ △)
                  @ △
                  @ (\"x1" (K@ (K@ ((Ref "q") @ (Ref "x1")))))
               )
             @ (△
                  @ (Ref "x")
                  @ △
                  @ (\"x1"
                       (\"x2"
                          (△
                             @ (K@ ((Ref "q") @(Ref "x1")))
                             @ (
                           ((Ref "q") @ (Ref "x2"))
       ))))))).

Definition quote := Y2 quote_aux. 

Ltac quote_tac :=
  unfold quote; eapply transitive_red;
  [ apply Y2_red
  | fold quote; unfold quote_aux; trtac; repeat apply preserves_app_t_red; zerotac].

Lemma quote_red: forall M, program M -> t_red(App quote M) (meta_quote M).
Proof.  intros M prM; induction prM; intros; quote_tac.  Qed.

Lemma meta_quote_of_combination_is_program: forall M, combination M -> program (meta_quote M).
Proof.  induction M; intros; inv1 combination; [ apply pr_leaf | apply pr_fork]; auto. Qed. 


(* Root evaluation is designed to act on meta_quotes *) 

Inductive root_eval: Tree -> Tree -> Prop :=
| root_leaf : root_eval △ △
| root_fork_leaf : forall f z, root_eval f △ -> root_eval (△ @ f @ z) (△ @ z)
| root_fork_stem: forall f z t, root_eval f (△ @ t) ->
                          root_eval(△ @ f @ z) (△ @ t @ z)
| root_fork_fork_fork_leaf : forall f z t y v,
    root_eval f (△ @ t @ y) -> root_eval t △ -> root_eval y v -> 
    root_eval(△ @ f @ z) v
| root_fork_fork_fork_stem: forall f z t y x v,
    root_eval f (△ @ t @ y) -> root_eval t (△ @ x) ->
    root_eval (△ @ (△ @ y @ z) @ (△ @ x @ z)) v -> 
    root_eval(△ @ f @ z) v
| root_fork_fork_fork_fork: forall f z t y w x v, 
    root_eval f (△ @ t @ y) -> root_eval t (△ @ w @ x) ->
    root_eval (△ @ (△ @ z @ w) @ x) v -> 
    root_eval(△ @ f @ z) v
.
              
Hint Constructors root_eval : TreeHintDb.


Ltac root_eval_tac := intros [ [? ( [=] & ?)] | [? [? ([=] & ? & ?)]]]; subst; eauto. 

Lemma root_eval_produces_meta_quote:
  forall M N, root_eval M N ->
              forall M0, combination M0 -> M = meta_quote M0 ->
                         (N = △ \/
                          (exists N1, N = △ @ meta_quote N1 /\ combination N1) \/
                          (exists N1 N2, N = △ @ (meta_quote N1) @ (meta_quote N2)
                                         /\ combination N1 /\ combination N2)). 
Proof.
  
Ltac elim_tac p := eelim p; [try discriminate | | | rewrite ? meta_quote_app; eauto]; auto.

intros M N e; induction e; intros M0 c eqM; subst; try discriminate;
     caseEq M0; intros; subst; inv1 combination; try discriminate; subst;
 simpl in *; inversion eqM; subst;  auto_t; 
   [elim_tac IHe; root_eval_tac; right; right; auto_t | | |];
   elim_tac IHe1; root_eval_tac; elim_tac IHe2; root_eval_tac; elim_tac IHe3;  combination_tac.
Qed.

Lemma root_eval_produces_stem:
  forall M N, root_eval M N ->
              forall M0 N0, combination M0 -> M = meta_quote M0 -> N = △ @ N0 ->
                            (exists N1, N0 = meta_quote N1 /\ combination N1). 
Proof.
  intros M N e M0 N0 cM0 eM eN;
  elim(root_eval_produces_meta_quote M N e M0 cM0 eM); subst; [discriminate | root_eval_tac]. 
Qed.

Lemma root_eval_produces_fork:
  forall M N, root_eval M N ->
              forall M0 N0 P0, combination M0 -> M = meta_quote M0 -> N = △ @ N0 @ P0 ->
                               (exists N1 P1, N0 = meta_quote N1 /\ combination N1 /\
                                              P0 = meta_quote P1 /\ combination P1). 
Proof.
  intros M N e M0 N0 P0 cM0 eM eN;
    elim(root_eval_produces_meta_quote M N e M0 cM0 eM); subst; 
  [ discriminate |root_eval_tac;  repeat eexists; eauto]. 
Qed.




(* The Representation *)

Definition rootl := \"r" (\"y" (\"z" (Ref "r" @ Ref "y"))). 
Definition roots :=
  Eval cbv in
    \"x" (\"r" (\"y" (\"z" (Ref "r" @ (△ @ (△ @ Ref "y" @ Ref "z") @ (△ @ Ref "x" @ Ref "z")))))).

Definition rootf :=
  Eval cbv in
  \"w"(\"x"(\"r"(\"y"(\"z"(Ref "r" @ (△ @ (△ @ Ref "z" @ Ref "w") @ Ref "x")))))). 

Definition root1 :=
  Eval cbv in
  \"t"(\"y"(\"r1"(triage rootl roots rootf @ (Ref "r1" @ Ref "t") @ (Ref "r1") @ (Ref "y")))).

Definition root_aux :=
  Eval cbv in (\"a"(\"r"(△ @ Ref "a" @ △ @ (\"f"(onFork root1 @ (Ref "r" @ Ref "f") @ (Ref "r")))))).

Definition root := Y2 root_aux. 
                       
Lemma root_program: program root.
Proof. program_tac. Qed.





Theorem root_eval_to_root: forall M P, root_eval M P -> t_red (root @ M) P.
Proof.
  intros M P ev; induction ev; intros;  
    (eapply transitive_red; [ apply Y2_red | fold root; unfold root_aux; trtac]);
    repeat (ap2tac; try zerotac; trtac).
Qed.


(* Root-and-Branch Evaluation *)

Inductive rb_eval : Tree -> Tree -> Prop :=
| rb_leaf : forall x, root_eval x △ -> rb_eval x △
| rb_stem : forall x y v, root_eval x (△ @ y) -> rb_eval y v -> rb_eval x (△ @ v)
| rb_fork : forall x y z v w, root_eval x (△ @ y@ z) -> rb_eval y v -> rb_eval z w ->
                                    rb_eval x (△ @ v @w)
.                                                                               

Hint Constructors rb_eval : TreeHIntDb. 
      

Definition rb_stem_case := Eval cbv in \"y" (\"r" (△ @ (Ref "r" @ Ref "y"))).
Definition rb_fork_case := Eval cbv in \"y" (\"z" (\"r" (△ @ (Ref "r" @ Ref "y")@ (Ref "r" @ Ref "z")))). 
Definition rb_aux := triage (K@△) rb_stem_case rb_fork_case.
Definition rb :=   Y2 (d root @ (K @ rb_aux)).

(*
Compute term_size root. 
Compute term_size rb. 942
*) 




Lemma rb_eval_implies_rb :
  forall M P, rb_eval M P -> forall M0, M = meta_quote M0 -> combination M0 -> t_red (rb @ M) P. 
Proof.
  intros M P e; induction e; intros M0 eqc c; subst. 
  
  assert(t_red (root @ (meta_quote M0)) △) by (apply root_eval_to_root; auto). 
  unfold rb. eapply transitive_red. apply Y2_red. unfold d; trtac.
  unfold rb_aux at 1; trtac. ap2tac; zerotac; trtac.
  aptac. apply triage_leaf.  zerotac. trtac. 

  assert(ex: exists Q, y = meta_quote Q /\ combination Q) by (eapply root_eval_produces_stem; eauto).
  elim ex; intros Q ([=] & c1); subst. 
  assert(t_red (root @ (meta_quote M0)) (△@ meta_quote Q)) by (eapply root_eval_to_root; eauto). 
  unfold rb. eapply transitive_red. apply Y2_red. fold rb.  unfold d; trtac.
  ap2tac; zerotac; trtac. unfold rb_aux; trtac.  aptac. apply triage_stem.  zerotac.
  unfold rb_stem_case; trtac. aptac. zerotac. eapply IHe; eauto. zerotac. 

  assert(ex: exists Q R , y = meta_quote Q /\ combination Q /\ z = meta_quote R /\ combination R)
    by (eapply root_eval_produces_fork; eauto).
  elim ex; intros Q ex2; elim ex2; intros R (e &c1 &e3 & c2); subst. 
  assert(t_red (root @ (meta_quote M0)) (△@ meta_quote Q @ meta_quote R)) by (apply root_eval_to_root; auto). 
  unfold rb. eapply transitive_red. apply Y2_red. fold rb.  unfold d; trtac.
  ap2tac; zerotac; trtac. unfold rb_aux; trtac.  aptac. apply triage_fork.  zerotac.
  unfold rb_fork_case; trtac. aptac. zerotac. eapply IHe2; eauto. aptac. aptac. zerotac. 
  eapply IHe1; eauto. all: zerotac.  
Qed.



(* Root-first evaluation performs quotation before root-and-branch evaluation *)

Definition root_first_eval M N P := rb_eval (△ @ (meta_quote M) @ (meta_quote N)) P.

Definition rf :=
  wait(\"q" (\"f" (\"z" (rb @ (△ @ ((Ref "q") @ (Ref "f")) @ ((Ref "q") @ (Ref "z"))))))) quote.

(* 
Compute (term_size rf). 
*) 




Theorem root_first_eval_implies_rf:
  forall M N P, program M -> program N -> root_first_eval M N P -> t_red (rf @ M @ N) P.
Proof.
  cut (forall M0 P, rb_eval M0 P ->
                    forall M N, M0 = △  @ meta_quote M @ meta_quote N ->
                                program M -> program N -> 
                                t_red (rf @ M @ N) P).
  intro c; intros; subst; eapply c; eauto.
  intros M0 P e M N eq prM prN; subst; 
  apply transitive_red with (rb @ meta_quote (M @ N));
  [
    unfold rf, wait, d, meta_quote; fold meta_quote; trtac;   
  starstac ("z" :: "f" :: "q" :: nil); 
  repeat (apply preserves_app_t_red; zerotac); apply quote_red; auto
  |
  eapply rb_eval_implies_rb; eauto; apply is_App; apply programs_are_combinations; auto
  ].
Qed.
