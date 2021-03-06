open! Import

module T = struct
  type t = int [@@deriving_inline hash, sexp]
  let t_of_sexp : Sexplib.Sexp.t -> t =
    let _tp_loc = "src/int.ml.T.t"  in fun t  -> int_of_sexp t
  let sexp_of_t : t -> Sexplib.Sexp.t = fun v  -> sexp_of_int v
  let (hash_fold_t :
         Ppx_hash_lib.Std.Hash.state -> t -> Ppx_hash_lib.Std.Hash.state) =
    fun hsv  -> fun arg  -> hash_fold_int hsv arg
  let (hash : t -> Ppx_hash_lib.Std.Hash.hash_value) =
    fun arg  ->
      Ppx_hash_lib.Std.Hash.get_hash_value
        (hash_fold_t (Ppx_hash_lib.Std.Hash.create ()) arg)

  [@@@end]

  let compare (x : t) y = Bool.to_int (x > y) - Bool.to_int (x < y)

  (* This shadows the [hash] definition coming from [@@deriving_inline hash][@@@end].
     The hash function there is different (significantly slower).
     Unfortunately, this means that the user writing [%hash: Int.t] will  get a different
     hash function from what they get when writing [Int.hash]. *)
  let _ = hash
  let hash (x : t) = if x >= 0 then x else ~-x

  let of_string s =
    try
      Caml.int_of_string s
    with
    | _ -> Printf.failwithf "Int.of_string: %S" s ()

  let to_string = string_of_int
end

include T
include Comparator.Make(T)

let num_bits = Int_conversions.num_bits_int

let float_lower_bound = Float0.lower_bound_for_int num_bits
let float_upper_bound = Float0.upper_bound_for_int num_bits

let to_float = Pervasives.float_of_int
let of_float_unchecked = Pervasives.int_of_float
let of_float f =
  if f >=. float_lower_bound && f <=. float_upper_bound then
    Pervasives.int_of_float f
  else
    Printf.invalid_argf "Int.of_float: argument (%f) is out of range or NaN"
      (Float0.box f)
      ()

module Replace_polymorphic_compare = struct
  let min (x : t) y = if x < y then x else y
  let max (x : t) y = if x > y then x else y
  let compare = compare
  let ascending = compare
  let descending x y = compare y x
  let equal (x : t) y = x = y
  let ( >= ) (x : t) y = x >= y
  let ( <= ) (x : t) y = x <= y
  let ( =  ) (x : t) y = x =  y
  let ( >  ) (x : t) y = x >  y
  let ( <  ) (x : t) y = x <  y
  let ( <> ) (x : t) y = x <> y
  let between t ~low ~high = low <= t && t <= high
  let clamp_unchecked t ~min ~max =
    if t < min then min else if t <= max then t else max

  let clamp_exn t ~min ~max =
    assert (min <= max);
    clamp_unchecked t ~min ~max

  let clamp t ~min ~max =
    if min > max then
      Or_error.error_s
        (Sexp.message "clamp requires [min <= max]"
           [ "min", T.sexp_of_t min
           ; "max", T.sexp_of_t max
           ])
    else
      Ok (clamp_unchecked t ~min ~max)
end

include Replace_polymorphic_compare

let zero = 0
let one = 1
let minus_one = -1

include Comparable.Validate_with_zero (struct
    include T
    let zero = zero
  end)

let pred i = i - 1
let succ i = i + 1

let to_int i = i
let to_int_exn = to_int
let of_int i = i
let of_int_exn = of_int

let max_value = Pervasives.max_int
let min_value = Pervasives.min_int

module Conv = Int_conversions
let of_int32 = Conv.int32_to_int
let of_int32_exn = Conv.int32_to_int_exn
let to_int32 = Conv.int_to_int32
let to_int32_exn = Conv.int_to_int32_exn
let of_int64 = Conv.int64_to_int
let of_int64_exn = Conv.int64_to_int_exn
let to_int64 = Conv.int_to_int64
let of_nativeint = Conv.nativeint_to_int
let of_nativeint_exn = Conv.nativeint_to_int_exn
let to_nativeint = Conv.int_to_nativeint
let to_nativeint_exn = to_nativeint

include Conv.Make (T)

include Conv.Make_hex(struct

    type t = int [@@deriving_inline compare, hash]
    let (hash_fold_t :
           Ppx_hash_lib.Std.Hash.state -> t -> Ppx_hash_lib.Std.Hash.state) =
      fun hsv  -> fun arg  -> hash_fold_int hsv arg
    let (hash : t -> Ppx_hash_lib.Std.Hash.hash_value) =
      fun arg  ->
        Ppx_hash_lib.Std.Hash.get_hash_value
          (hash_fold_t (Ppx_hash_lib.Std.Hash.create ()) arg)

    let compare : t -> t -> int =
      fun a__001_  -> fun b__002_  -> compare_int a__001_ b__002_
    [@@@end]

    let zero = zero
    let neg = (~-)
    let (<) = (<)
    let to_string i = Printf.sprintf "%x" i
    let of_string s = Caml.Scanf.sscanf s "%x" Fn.id

    let module_name = "Base.Int.Hex"

  end)

let abs x = abs x

let ( + ) x y = ( + ) x y
let ( - ) x y = ( - ) x y
let ( * ) x y = ( * ) x y
let ( / ) x y = ( / ) x y

let neg x = -x
let ( ~- ) = neg

(* note that rem is not same as % *)
let rem a b = a mod b

let incr = Pervasives.incr
let decr = Pervasives.decr

let shift_right a b = a asr b
let shift_right_logical a b = a lsr b
let shift_left a b = a lsl b
let bit_not a = lnot a
let bit_or a b = a lor b
let bit_and a b = a land b
let bit_xor a b = a lxor b

let pow = Int_math.int_pow

include Int_pow2

(* This is already defined by Comparable.Validate_with_zero, but Sign.of_int is
   more direct. *)
let sign = Sign.of_int

let popcount = Popcount.int_popcount

include Pretty_printer.Register (struct
    type nonrec t = t
    let to_string = to_string
    let module_name = "Base.Int"
  end)

module Pre_O = struct
  let ( + ) = ( + )
  let ( - ) = ( - )
  let ( * ) = ( * )
  let ( / ) = ( / )
  let ( ~- ) = ( ~- )
  include (Replace_polymorphic_compare : Polymorphic_compare_intf.Infix with type t := t)
  let abs = abs
  let neg = neg
  let zero = zero
  let of_int_exn = of_int_exn
end

module O = struct
  include Pre_O
  module F = Int_math.Make (struct
      type nonrec t = t
      include Pre_O
      let rem = rem
      let to_float = to_float
      let of_float = of_float
      let of_string = T.of_string
      let to_string = T.to_string
    end)
  include F

  (* These inlined versions of (%), (/%), and (//) perform better than their functorized
     counterparts in [F] (see benchmarks below).

     The reason these functions are inlined in [Int] but not in any of the other integer
     modules is that they existed in [Int] and [Int] alone prior to the introduction of
     the [Int_math.Make] functor, and we didn't want to degrade their performance.

     We won't pre-emptively do the same for new functions, unless someone cares, on a case
     by case fashion.  *)

  let ( % ) x y =
    if y <= zero then
      Printf.invalid_argf
        "%s %% %s in core_int.ml: modulus should be positive"
        (to_string x) (to_string y) ();
    let rval = rem x y in
    if rval < zero
    then rval + y
    else rval
  ;;

  let ( /% ) x y =
    if y <= zero then
      Printf.invalid_argf
        "%s /%% %s in core_int.ml: divisor should be positive"
        (to_string x) (to_string y) ();
    if x < zero
    then (x + one) / y - one
    else x / y
  ;;

  let (//) x y = to_float x /. to_float y
  ;;

  let ( land ) = ( land )
  let ( lor  ) = ( lor  )
  let ( lxor ) = ( lxor )
  let ( lnot ) = ( lnot )
  let ( lsl  ) = ( lsl  )
  let ( asr  ) = ( asr  )
  let ( lsr  ) = ( lsr  )
end

include O (* [Int] and [Int.O] agree value-wise *)

module Private = struct
  module O_F = O.F
end
