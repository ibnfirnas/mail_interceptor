open Core.Std
open Async.Std

module Flag = struct
  open Command.Spec

  module Default = struct
    let port      = 2525
    let log_level = "Info"
  end

  let directory =
    flag "--storage-directory" (required string)
    ~doc:" Where to store intercepted messages?"

  let port =
    flag "--port" (optional_with_default Default.port int)
    ~doc:(sprintf " TCP port to listen on. Default: %d" Default.port)

  let log_level =
    flag "--log-level" (optional_with_default Default.log_level string)
    ~doc:(sprintf " Log level [Debug | Info | Error]. Default: %s" Default.log_level)
end

module Spec = struct
  let for_start =
    let (+) = Command.Spec.(+>) in
    ( Command.Spec.empty
    + Flag.directory
    + Flag.port
    + Flag.log_level
    )
end

let command_start_foreground =
  Command.async_basic
    ~summary:"Start server in the foreground."
    Spec.for_start
    ( fun directory port log_level () ->
        Mail_interceptor_server.start
          ~directory
          ~port
          ~log_level:(Log.Level.of_string log_level)
          ~release_parent:(fun () -> ())
    )

let command_start_daemon =
  Command.async_basic
    ~summary:"Start server in the background (daemonize)."
    Spec.for_start
    ( fun directory port log_level () ->
        let release_parent =
          Staged.unstage (Daemon.daemonize_wait ~cd:directory ())
        in
        Mail_interceptor_server.start
          ~directory
          ~port
          ~log_level:(Log.Level.of_string log_level)
          ~release_parent
    )

let command =
  Command.group
    ~summary:""
    [ "run"   , command_start_foreground
    ; "start" , command_start_daemon
    ]

let () =
  Command.run command
