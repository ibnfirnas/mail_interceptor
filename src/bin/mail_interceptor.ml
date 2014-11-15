open Core.Std
open Async.Std

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
        Mail_interceptor_server.start
          ~directory
          ~port
          ~log_level
          ~release_parent
    )
  )
