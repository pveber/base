open! Import

type 'a t = 'a option [@@deriving_inline sexp, compare, hash]
let hash_fold_t :
  'a .
    (Ppx_hash_lib.Std.Hash.state -> 'a -> Ppx_hash_lib.Std.Hash.state) ->
  Ppx_hash_lib.Std.Hash.state -> 'a t -> Ppx_hash_lib.Std.Hash.state
  =
  fun _hash_fold_a  ->
  fun hsv  ->
  fun arg  ->
    hash_fold_option (fun hsv  -> fun arg  -> _hash_fold_a hsv arg) hsv
      arg

let compare : 'a . ('a -> 'a -> int) -> 'a t -> 'a t -> int =
  fun _cmp__a  ->
  fun a__001_  -> fun b__002_  -> compare_option _cmp__a a__001_ b__002_

let t_of_sexp : 'a . (Sexplib.Sexp.t -> 'a) -> Sexplib.Sexp.t -> 'a t =
  let _tp_loc = "src/option.ml.t"  in
  fun _of_a  -> fun t  -> (option_of_sexp _of_a) t
let sexp_of_t : 'a . ('a -> Sexplib.Sexp.t) -> 'a t -> Sexplib.Sexp.t =
  fun _of_a  -> fun v  -> (sexp_of_option _of_a) v
[@@@end]

let is_none = function None -> true | _ -> false

let is_some = function Some _ -> true | _ -> false

let value_map o ~default ~f =
  match o with
  | Some x -> f x
  | None   -> default

let iter o ~f =
  match o with
  | None -> ()
  | Some a -> f a
;;

let invariant f t = iter t ~f

let map2 o1 o2 ~f =
  match o1, o2 with
  | Some a1, Some a2 -> Some (f a1 a2)
  | _ -> None

let call x ~f =
  match f with
  | None -> ()
  | Some f -> f x

let value t ~default =
  match t with
  | None -> default
  | Some x -> x
;;

let value_exn ?here ?error ?message t =
  match t with
  | Some x -> x
  | None ->
    let error =
      match here, error, message with
      | None  , None  , None   -> Error.of_string "Option.value_exn None"
      | None  , None  , Some m -> Error.of_string m
      | None  , Some e, None   -> e
      | None  , Some e, Some m -> Error.tag e ~tag:m
      | Some p, None  , None   ->
        Error.create "Option.value_exn" p Source_code_position0.sexp_of_t
      | Some p, None  , Some m ->
        Error.create m p Source_code_position0.sexp_of_t
      | Some p, Some e, _      ->
        Error.create (value message ~default:"") (e, p)
          (sexp_of_pair Error.sexp_of_t Source_code_position0.sexp_of_t)
    in
    Error.raise error
;;

let to_array t =
  match t with
  | None -> [||]
  | Some x -> [|x|]
;;

let to_list t =
  match t with
  | None -> []
  | Some x -> [x]
;;

let min_elt t ~cmp:_ = t
let max_elt t ~cmp:_ = t
let sum (type a) (module M : Commutative_group.S with type t = a) t ~f =
  match t with
  | None -> M.zero
  | Some x -> f x
;;

let for_all t ~f =
  match t with
  | None -> true
  | Some x -> f x
;;

let exists t ~f =
  match t with
  | None -> false
  | Some x -> f x
;;

let mem t a ~equal =
  match t with
  | None -> false
  | Some a' -> equal a a'
;;

let length t =
  match t with
  | None -> 0
  | Some _ -> 1
;;

let is_empty = is_none

let fold t ~init ~f =
  match t with
  | None -> init
  | Some x -> f init x
;;

let count t ~f =
  match t with
  | None -> 0
  | Some a -> if f a then 1 else 0
;;

let find t ~f =
  match t with
  | None -> None
  | Some x -> if f x then Some x else None
;;

let find_map t ~f =
  match t with
  | None -> None
  | Some a -> f a
;;

let equal f t t' =
  match t, t' with
  | None, None -> true
  | Some x, Some x' -> f x x'
  | _ -> false

let some x = Some x

let both x y =
  match x,y with
  | Some a, Some b -> Some (a,b)
  | _ -> None

let first_some x y =
  match x with
  | Some _ -> x
  | None -> y

let some_if cond x = if cond then Some x else None

let merge a b ~f =
  match a, b with
  | None, x | x, None -> x
  | Some a, Some b -> Some (f a b)

let filter t ~f =
  match t with
  | Some v as o when f v -> o
  | _ -> None

let try_with f =
  try Some (f ())
  with _ -> None

include Monad.Make (struct
    type 'a t = 'a option
    let return x = Some x
    let map t ~f =
      match t with
      | None -> None
      | Some a -> Some (f a)
    ;;
    let map = `Custom map
    let bind o ~f =
      match o with
      | None -> None
      | Some x -> f x
  end)

let fold_result t ~init ~f = Container.fold_result ~fold ~init ~f t
let fold_until  t ~init ~f = Container.fold_until  ~fold ~init ~f t

let validate ~none ~some t =
  let module V = Validate in
  match t with
  | None   -> V.name "none" (V.protect none ())
  | Some x -> V.name "some" (V.protect some x )
;;
