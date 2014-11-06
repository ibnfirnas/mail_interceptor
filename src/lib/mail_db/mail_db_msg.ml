open Core.Std

type t =
  { time : Time.t
  ; raw  : string
  }

let cons ~time ~email_msg =
  { time
  ; raw = Email_message.Email.to_string email_msg
  }
