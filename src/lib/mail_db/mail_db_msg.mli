open Core.Std

type t = private
  { time : Time.t
  ; raw  : string
  }

val cons : time:Time.t -> email_msg:Email_message.Email.t -> t
