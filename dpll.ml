open List

(* fonctions utilitaires *********************************************)
(* filter_map : ('a -> 'b option) -> 'a list -> 'b list
   disponible depuis la version 4.08.0 de OCaml dans le module List :
   pour chaque élément de `list', appliquer `filter' :
   - si le résultat est `Some e', ajouter `e' au résultat ;
   - si le résultat est `None', ne rien ajouter au résultat.
   Attention, cette implémentation inverse l'ordre de la liste *)
let filter_map (filter : 'a -> 'b option) (list : 'a list) : 'b list =
  let rec aux list ret =
    match list with
    | []   -> ret
    | h::t -> match (filter h) with
      | None   -> aux t ret
      | Some e -> aux t (e::ret)
  in aux list []

(* print_modele : int list option -> unit
   affichage du résultat *)
let print_modele: int list option -> unit = function
  | None   -> print_string "UNSAT\n"
  | Some modele -> print_string "SAT\n";
     let modele2 = sort (fun i j -> (abs i) - (abs j)) modele in
     List.iter (fun i -> print_int i; print_string " ") modele2;
     print_string "0\n"

(* ensembles de clauses de test *)
let exemple_3_12 = [[1;2;-3];[2;3];[-1;-2;3];[-1;-3];[1;-2]]
let exemple_7_2 = [[1;-1;-3];[-2;3];[-2]]
let exemple_7_4 = [[1;2;3];[-1;2;3];[3];[1;-2;-3];[-1;-2;-3];[-3]]
let exemple_7_8 = [[1;-2;3];[1;-3];[2;3];[1;-2]]
let systeme = [[-1;2];[1;-2];[1;-3];[1;2;3];[-1;-2]]
let coloriage = [[1;2;3];[4;5;6];[7;8;9];[10;11;12];[13;14;15];[16;17;18];[19;20;21];[-1;-2];[-1;-3];[-2;-3];[-4;-5];[-4;-6];[-5;-6];[-7;-8];[-7;-9];[-8;-9];[-10;-11];[-10;-12];[-11;-12];[-13;-14];[-13;-15];[-14;-15];[-16;-17];[-16;-18];[-17;-18];[-19;-20];[-19;-21];[-20;-21];[-1;-4];[-2;-5];[-3;-6];[-1;-7];[-2;-8];[-3;-9];[-4;-7];[-5;-8];[-6;-9];[-4;-10];[-5;-11];[-6;-12];[-7;-10];[-8;-11];[-9;-12];[-7;-13];[-8;-14];[-9;-15];[-7;-16];[-8;-17];[-9;-18];[-10;-13];[-11;-14];[-12;-15];[-13;-16];[-14;-17];[-15;-18]]

(********************************************************************)

(* simplifie : int -> int list list -> int list list
   applique la simplification de l'ensemble des clauses en mettant
   le littéral l à vrai *)

let simplifie (l : int) (clauses : int list list) : int list list =
  (* simplifie_clause : int list -> int list option
     applique la simplification de la clause en mettant
     le littéral l à vrai

     retourne None si la clause vaut 1, Some _ sinon *)
  let rec simplifie_clause : int list -> int list option = function
    | [] -> Some []
    | h :: t when  h = l -> None
    | h :: t when -h = l -> simplifie_clause t
    | h :: t -> Option.map (fun rest -> h :: rest) (simplifie_clause t)
  in
  filter_map simplifie_clause clauses


(* solveur_split : int list list -> int list -> int list option
   exemple d'utilisation de `simplifie' *)
(* cette fonction ne doit pas être modifiée, sauf si vous changez
   le type de la fonction simplifie *)
let rec solveur_split
          (clauses : int list list)
          (interpretation : int list)
        : int list option =
  (* l'ensemble vide de clauses est satisfiable *)
  if clauses = [] then Some interpretation else
  (* un clause vide n'est jamais satisfiable *)
  if mem [] clauses then None else
  (* branchement *)
  let l = hd (hd clauses) in
  let branche = solveur_split (simplifie l clauses) (l::interpretation) in
  match branche with
  | None -> solveur_split (simplifie (-l) clauses) ((-l)::interpretation)
  | _    -> branche


(* tests *)
(* let () = print_modele (solveur_split systeme []) *)
(* let () = print_modele (solveur_split coloriage []) *)

(* solveur dpll récursif *)

(* unitaire : int list list -> int
    - si `clauses' contient au moins une clause unitaire, retourne
      le littéral de cette clause unitaire ;
    - sinon, retourne None *)
let rec unitaire : int list list -> int option = function
  | [] -> None
  | [x] :: _ -> Some x
  | _ :: t -> unitaire t

(* pur : int list list -> int
    - si `clauses' contient au moins un littéral pur, retourne
      ce littéral ;
    - sinon, renvoie None *)
let pur (clauses : int list list) : int option =
  (*                         version recursive terminale de List.concat  *)
  let litteraux : int list = fold_left rev_append [] clauses in
  let litteral_pur (l : int) : bool = not (mem (-l) litteraux) in

  match find_opt litteral_pur litteraux with
  | None -> None
  | Some x -> Some x



(* solveur_dpll_rec : int list list -> int list -> int list option *)
let rec solveur_dpll_rec
          (clauses : int list list)
          (interpretation : int list)
        : int list option =

  let solveur_litteral l =
    solveur_dpll_rec (simplifie l clauses) (l :: interpretation) in

  let solveur_split () : int list option =
    let l = hd (hd clauses) in
    match solveur_dpll_rec (simplifie l clauses) (l :: interpretation) with
    | Some i -> Some i
    | None -> solveur_dpll_rec (simplifie (-l) clauses) ((-l) :: interpretation)
  in

  (* l'ensemble vide de clauses est satisfiable *)
  if clauses = [] then Some interpretation else
  (* un clause vide n'est jamais satisfiable *)
  if mem [] clauses then None else

    match unitaire clauses with
    | Some l -> solveur_litteral l
    | None ->
       match pur clauses with
       | Some l -> solveur_litteral l
       | None -> solveur_split ()


(* tests *)
let () = print_modele (solveur_dpll_rec systeme [])
let () = print_modele (solveur_dpll_rec coloriage [])

let () =
  let clauses = Dimacs.parse Sys.argv.(1) in
  print_modele (solveur_dpll_rec clauses [])
