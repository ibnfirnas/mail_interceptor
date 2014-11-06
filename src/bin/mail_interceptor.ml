open Core.Std
open Async.Std

module Smtp = Async_smtp.Smtp

module Supervisor : sig
  val run : (unit -> unit Deferred.t) list -> unit Deferred.t
end = struct
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
end

let main ~directory ~port ~log_level ~release_parent =
  let log_dir_path  = directory    ^/ "log" in
  let log_file_path = log_dir_path ^/ "console.log" in
  Async_shell.mkdir ~p:() log_dir_path
  >>= fun () ->
  Log.Global.set_level log_level;
  Log.Global.set_output
    [ Log.Output.stderr ()
    ; Log.Output.file `Text ~filename:log_file_path
    ];
  let smtp_msgs_r, smtp_msgs_w = Pipe.create () in
  Mail_db.init ~directory
  >>= fun db ->
  let worker_storer () =
    let store_smtp_msg (_sender, receivers, _email_id, email_msg) =
      let msg = Email_message.Email.to_string email_msg in
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
  in
  let worker_server () =
    let router ~addr ~r ~w =
      let routing_rule smtp_msg =
        Pipe.write_without_pushback smtp_msgs_w smtp_msg;
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
  in
  release_parent ();
  Supervisor.run
    [ worker_storer
    ; worker_server
    ]

let () =
  let (+) = Command.Spec.(+>) in
  Command.run (Command.async_basic
    ~summary:""
    Command.Spec.
    ( empty
    + flag "--storage-directory" (required string)
        ~doc:" Where to store intercepted messages?"
    + flag "--port" (optional_with_default 2525 int)
        ~doc:" TCP port to listen on. Default: 2525"
    + flag "--log-level" (optional_with_default "Info" string)
        ~doc:" Log level [Debug | Info | Error]. Default: Info"
    + flag "--daemonize" no_arg
        ~doc:" Shall we daemonize? Default: no"
    )
    ( fun directory port log_level daemonize () ->
        let log_level = Log.Level.of_string log_level in
        let release_parent =
          if daemonize then
            Staged.unstage (Daemon.daemonize_wait ~cd:directory ())
          else
            fun () -> ()
        in
        main ~directory ~port ~log_level ~release_parent
    )
  )
