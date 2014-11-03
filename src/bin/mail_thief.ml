open Core.Std
open Async.Std

module Smtp = Async_smtp.Smtp

module Supervisor = struct
  let rec run f =
    try_with f >>= function
    | Ok x -> return x
    | Error e ->
        eprintf "Failure: %s\n%!" (Exn.to_string e);
        run f
end

let main () =
  Log.Global.set_level `Debug;
  Log.Global.set_output [Log.Output.stderr ()];
  let rewriting_rules = [] in
  let   routing_rules =
    [ fun (sender, _receivers, _email_id, _email_msg) ->
        Log.Global.info ">>> Got msg from: %S\n%!" sender;
        None
    ]
  in
  (Tcp.Server.create
    ~on_handler_error:`Raise
    (Tcp.on_port 2525)
    (fun addr r w ->
      Supervisor.run
        (fun () ->
          Smtp.Router.rules_server
            rewriting_rules
              routing_rules
            addr
            r
            w
        )
  ))
  |> ignore;
  Deferred.never ()

let () =
  Command.run (
    Command.async_basic
      ~summary:""
      Command.Spec.empty
      (fun () -> main ())
  )
