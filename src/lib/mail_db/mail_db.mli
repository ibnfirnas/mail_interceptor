open Core.Std
open Async.Std

type t

val init : directory:string -> t Deferred.t

val store : t -> receiver:string -> msg:string -> unit Deferred.t
