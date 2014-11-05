open Core.Std
open Async.Std

module Digest : sig
  type t = string

  val of_string : string -> t
end = struct
  type t = string

  let of_string message =
    let hash = Cryptokit.Hash.sha3 256 in
    let hex = Cryptokit.Hexa.encode () in
    hash#add_string message;
    hex#put_string hash#result;
    hex#get_string
end

type t =
  { dir_messages  : string
  ; dir_mailboxes : string
  }

let ( / ) = Filename.concat

let ensure_directories {dir_messages; dir_mailboxes} =
  Async_shell.mkdir ~p:() dir_messages >>= fun () ->
  Async_shell.mkdir ~p:() dir_mailboxes

let init ~directory:root =
  let subdir_messages  = "messages" in
  let subdir_mailboxes = "mailboxes" in
  let t =
    { dir_messages  = root / subdir_messages
    ; dir_mailboxes = root / subdir_mailboxes
    }
  in
  return t

let store ({dir_messages; dir_mailboxes} as t) ~receiver ~msg =
  let msg_digest = Digest.of_string msg in
  let path_to_msg      = dir_messages  / msg_digest in
  let path_to_manifest = dir_mailboxes / receiver in
  ensure_directories t
  >>= fun () ->
  Writer.save path_to_msg ~contents:msg
  >>= fun () ->
  File_writer.create ~append:true path_to_manifest
  >>= fun file_manifest ->
  File_writer.write file_manifest msg_digest;
  File_writer.write file_manifest "\n";
  File_writer.close file_manifest
