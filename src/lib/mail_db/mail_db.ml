open Core.Std
open Async.Std

type t =
  { dir_messages  : string
  ; dir_mailboxes : string
  }

let digest_of_string s =
  let hash      = Cryptokit.Hash.sha3 256 in
  let transform = Cryptokit.Hexa.encode () in
  Cryptokit.transform_string transform (Cryptokit.hash_string hash s)

let file_append_line ~dir ~filename ~data =
  Async_shell.mkdir ~p:() dir
  >>= fun () ->
  File_writer.create ~append:true (dir ^/ filename)
  >>= fun file_manifest ->
  File_writer.write file_manifest data;
  File_writer.write file_manifest "\n";
  File_writer.close file_manifest

let file_overwrite ~dir ~filename ~data =
  Async_shell.mkdir ~p:() dir
  >>= fun () ->
  Writer.save (dir ^/ filename) ~contents:data

let init ~directory:root =
  let subdir_messages  = "messages" in
  let subdir_mailboxes = "mailboxes" in
  let t =
    { dir_messages  = root ^/ subdir_messages
    ; dir_mailboxes = root ^/ subdir_mailboxes
    }
  in
  return t

let store {dir_messages; dir_mailboxes} ~receiver ~msg =
  let msg_digest = digest_of_string msg in
  file_overwrite   ~dir:dir_messages  ~filename:msg_digest ~data:msg >>= fun () ->
  file_append_line ~dir:dir_mailboxes ~filename:receiver   ~data:msg_digest
