open Core.Std
open Async.Std

module Smtp = Async_smtp.Smtp

let worker_storer ~smtp_msgs_r ~db () =
  let store_smtp_msg (time, (_sender, receivers, _email_id, email_msg)) =
    let msg = Mail_db_msg.cons ~time ~email_msg in
    Deferred.List.iter receivers ~how:`Parallel ~f:(fun receiver ->
      Log.Global.debug "Storing messsage for receiver: %s" receiver;
      let receiver = receiver
        |> String.lstrip ~drop:((=) '<')
        |> String.rstrip ~drop:((=) '>')
      in
      Mail_db.store db ~receiver ~msg
    )
  in
  Pipe.iter smtp_msgs_r ~f:store_smtp_msg

let worker_server ~smtp_msgs_w ~port () =
  let router ~addr ~r ~w =
    let routing_rule smtp_msg =
      Pipe.write_without_pushback smtp_msgs_w (Time.now (), smtp_msg);
      None
    in
    Smtp.Router.rules_server [] [routing_rule] addr r w
  in
  ( Tcp.Server.create
      ~on_handler_error:`Raise
      (Tcp.on_port port)
      (fun addr r w -> router ~addr ~r ~w)
  )
  >>= fun _address ->
  Deferred.never ()

let start ~directory ~port ~log_level ~release_parent =
  let log_dir_path  = directory    ^/ "log" in
  let log_file_path = log_dir_path ^/ "console.log" in
  Async_shell.mkdir ~p:() log_dir_path
  >>= fun () ->
  Log.Global.set_level log_level;
  Log.Global.set_output
    [ Log.Output.stderr ()
    ; Log.Output.file `Text ~filename:log_file_path
    ];
  Mail_db.init ~directory
  >>= fun db ->
  let smtp_msgs_r, smtp_msgs_w = Pipe.create () in
  release_parent ();
  Supervisor.run
    [ worker_storer ~smtp_msgs_r ~db
    ; worker_server ~smtp_msgs_w ~port
    ]
