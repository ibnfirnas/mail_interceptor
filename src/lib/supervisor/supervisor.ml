open Core.Std
open Async.Std

let rec restart_on_exn f =
  Log.Global.debug "Supervisor running child.";
  try_with f >>= function
  | Ok () ->
      return ()
  | Error e ->
      Log.Global.error "Supervisor caught failure: %s" (Exn.to_string e);
      restart_on_exn f

let run workers =
  Deferred.List.iter
    ~how:`Parallel
    ~f:restart_on_exn
    workers
