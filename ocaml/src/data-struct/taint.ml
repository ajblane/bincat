(*
    This file is part of BinCAT.
    Copyright 2014-2017 - Airbus Group

    BinCAT is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as published by
    the Free Software Foundation, either version 3 of the License, or (at your
    option) any later version.

    BinCAT is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with BinCAT.  If not, see <http://www.gnu.org/licenses/>.
*)

(* data type tainting source *)
module Src =
  struct

    (* type of tainting sources *) 
    type src_id = int

    (*current id for the generation of fresh taint sources *)
    let (current_id: src_id ref) = ref 0
      
  
    (* a value may be surely Tainted or Maybe tainted *)
    type t =
      | Tainted of src_id (** surely tainted by the given source *)
      | Maybe of src_id (** maybe tainted by then given source *)

    (* returns a fresh source id and increments src_id *)
    let make_sure () =
      current_id := !current_id + 1;
      Tainted (!current_id)

    (* returns a fresh possible source id and increments src_id *)
    let make_uncertain () =
      current_id := !current_id + 1;
      Maybe (!current_id)
        
    (* comparison between tainting sources. Returns
    - 0 is equal
    - a negative number if the first source is less than the second one
    - a positive number otherwise *)
    let compare (src1: t) (src2: t): int =
      match src1, src2 with
      | Tainted id1, Tainted id2 -> id1 - id2
      | Tainted _, _ -> -1
      | Maybe _, Tainted _ -> 1
      | Maybe id1, Maybe id2 -> id1 - id2
  end

(* set of (possible) tainting sources *)
module SrcSet = Set.Make (Src)
 

(* a taint value can be 
   - untainted (U) 
   - or a set (S) of (possible) tainting sources 
   - or an unknown taint (TOP) *)  
type t =
  | U
  | S of SrcSet.t
  | TOP    

let make_sure () = S (SrcSet.singleton (Src.make_sure ()))

let make_uncertain () = S (SrcSet.singleton (Src.make_uncertain ()))

let join (t1: t) (t2: t): t =
  match t1, t2 with
  | U, U -> U
  | _, U  | U, _ -> TOP
  | S src1, S src2 -> S (SrcSet.union src1 src2) 
  | TOP, _  | _, TOP -> TOP

let logor (t1: t) (t2: t): t =
  match t1, t2 with
  | U, U -> U
  | t, U  | U, t -> t 
  | S src1, S src2 -> S (SrcSet.union src1 src2)
  | _, _ -> TOP
     
let logand (t1: t) (t2: t): t =
  match t1, t2 with
  | U, U -> U
  | _, U | U, _ -> U
  | S src1, S src2 ->
     let src' = SrcSet.inter src1 src2 in
     if SrcSet.is_empty src' then U
     else S src'
  | S src, TOP | TOP, S src -> S src
  | TOP, TOP -> TOP
     
let meet (t1: t) (t2: t): t =
  match t1, t2 with
  | U, U -> U
  | U, TOP | TOP, U -> U  
  | _, U | U, _ -> raise Exceptions.Empty  
  | S src1, S src2 -> S (SrcSet.inter src1 src2)
  | S src, TOP | TOP, S src -> S src
  | TOP, TOP -> TOP
     
let to_char (t: t): char =
  match t with
  | TOP -> '?'
  | S _ -> '1'
  | U -> '0'

let to_string (t: t): string =
  match t with
  | TOP -> "?"
  | S _ -> "1"
  | U   -> "0"

let equal (t1: t) (t2: t): bool =
  match t1, t2 with
  | U, U -> true
  | TOP, _ | _, TOP -> true
  | S src1, S src2 -> SrcSet.compare src1 src2 = 0
  | _, _ -> false
     
let binary (carry: t option) (t1: t) (t2: t): t =
  match t1, t2 with
  | TOP, _ | _, TOP -> TOP
  | t, U | U, t -> 
     begin
       match carry with
       | None -> t
       | Some csrc -> join csrc t 
     end
        
  | S src1, S src2 ->
     let src' = SrcSet.union src1 src2 in
     begin
       match carry with
       | None -> S src'
       | Some csrc -> join csrc (S src')
     end
 
        
						    
let add = binary
let sub = binary
let xor = binary None
let neg v = v

(* finite lattice => widen = join *)
let widen = join

(* default tainting value is Untainted *)
let default = U

let untaint (_t: t): t = U
let taint (t: t): t = t

let min (t1: t) (t2: t): t =
  match t1, t2 with
  | U, t  | t, U -> t
  | S src, TOP  | TOP, S src -> S src
  | S src1, S src2 -> if SrcSet.compare src1 src2 <= 0 then t1 else t2
  | TOP, TOP -> TOP
     
		      
let is_tainted (t: t): bool =
  match t with
  | S _ | TOP -> true
  | U	    -> false

let to_z (t: t): Z.t =
  match t with
  | U -> Z.zero
  | S _ -> Z.one
  | _ -> raise Exceptions.Concretization
