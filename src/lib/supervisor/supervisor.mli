open Core.Std
open Async.Std

val run : (unit -> unit Deferred.t) list -> unit Deferred.t
