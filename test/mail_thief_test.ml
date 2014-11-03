open Core.Std
open Async.Std


module Log  = Caravan.Log
module Test = Caravan.Test
module Smtp = Async_smtp.Smtp

let t_send =
  let case state ~log:_ =
    Tcp.connect (Tcp.to_host_and_port "localhost" 2525)
    >>= fun (_addr, r, w) -> 
    Smtp.Client.send_email
      r
      w
      ~from:"foo@bar"
      ~to_:["baz@qux"]
      "\nTest"
    >>= fun is_sent_successful ->
    assert is_sent_successful;
    return state
  in
  {Test.id = "t_send"; case; children = []}


let main () =
  let tests =
    [ t_send
    ]
  in
  Caravan.run ~tests ~init_state:()

let () =
  Command.run (Command.async_basic ~summary:"" Command.Spec.empty main)
