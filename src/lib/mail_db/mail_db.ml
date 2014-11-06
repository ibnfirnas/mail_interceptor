open Core.Std
open Async.Std

module Csv_writer = Core_extended.Std.Csv_writer

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

let subdir_messages  = "messages"
let subdir_mailboxes = "mailboxes"

let init ~directory:root =
  let t =
    { dir_messages  = root ^/ subdir_messages
    ; dir_mailboxes = root ^/ subdir_mailboxes
    }
  in
  return t

let store {dir_messages; dir_mailboxes} ~receiver ~msg =
  let {Mail_db_msg.time; raw=msg_raw} = msg in
  let time = Time.to_string time in
  let receiver_dot_csv  = receiver ^ ".csv" in
  let receiver_dot_html = receiver ^ ".html" in
  let msg_digest = digest_of_string msg_raw in
  let msg_meta_csv = Csv_writer.line_to_string ~sep:'|' [time; msg_digest] in
  let msg_meta_html =
    sprintf
      "<li>%s <a href=\"/%s/%s\">%s</a></li>"
      time
      subdir_messages
      msg_digest
      msg_digest
  in
  file_overwrite   ~dir:dir_messages  ~filename:msg_digest        ~data:msg_raw
  >>= fun () ->
  file_append_line ~dir:dir_mailboxes ~filename:receiver_dot_csv  ~data:msg_meta_csv
  >>= fun () ->
  file_append_line ~dir:dir_mailboxes ~filename:receiver_dot_html ~data:msg_meta_html
