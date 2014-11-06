open Core.Std
open Async.Std

type t

val init : directory:string -> t Deferred.t

val store : t -> receiver:string -> msg:Mail_db_msg.t -> unit Deferred.t
