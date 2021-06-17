(*
 * This file has been generated by the OCamlClientCodegen generator for openapi-generator.
 *
 * Generated by: https://openapi-generator.tech
 *
 * Schema Network_request.t : A NetworkRequest is utilized to retrieve some data specific exclusively to a NetworkIdentifier.
 *)

type t =
  { network_identifier : Network_identifier.t
  ; metadata : Yojson.Safe.t option [@default None]
  }
[@@deriving yojson { strict = false }, show]

(** A NetworkRequest is utilized to retrieve some data specific exclusively to a NetworkIdentifier. *)
let create (network_identifier : Network_identifier.t) : t =
  { network_identifier; metadata = None }
