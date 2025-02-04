open Mina_base
open Core_kernel

type failure =
  | Invalid_account_precondition
  | Invalid_protocol_state_precondition
  | Update_not_permitted of
      [ `Delegate
      | `App_state
      | `Voting_for
      | `Verification_key
      | `Zkapp_uri
      | `Token_symbol
      | `Balance ]

type role = [ `Fee_payer | `New_account | `Ordinary_participant ]

val max_other_parties : int

val gen_account_precondition_from_account :
     ?failure:failure
  -> first_use_of_account:bool
  -> Account.t
  -> Party.Account_precondition.t Quickcheck.Generator.t

val gen_protocol_state_precondition :
     Zkapp_precondition.Protocol_state.View.t
  -> Zkapp_precondition.Protocol_state.t Quickcheck.Generator.t

(** `gen_parties_from` generates a parties and record the change of accounts accordingly
    in `account_state_tbl`. Note that `account_state_tbl` is optional. If it's not provided
    then it would be computed from the ledger. If you plan to generate several parties,
    then please manually pass `account_state_tbl` to `gen_parties_from` function.
    If you are generating several parties, it's better to pre-compute the
    `account_state_tbl` before you call this function. This way you can manually set the
    role of fee payer accounts to be `Fee_payer` in `account_state_tbl` which would prevent
    those accounts being used as ordinary participants in other parties.

    Generated parties uses dummy signatures and dummy proofs.
  *)
val gen_parties_from :
     ?failure:failure
  -> ?max_other_parties:int
  -> fee_payer_keypair:Signature_lib.Keypair.t
  -> keymap:
       Signature_lib.Private_key.t Signature_lib.Public_key.Compressed.Map.t
  -> ?account_state_tbl:(Account.t * role) Account_id.Table.t
  -> ledger:Mina_ledger.Ledger.t
  -> ?protocol_state_view:Zkapp_precondition.Protocol_state.View.t
  -> ?vk:(Side_loaded_verification_key.t, State_hash.t) With_hash.Stable.V1.t
  -> unit
  -> Parties.t Quickcheck.Generator.t

(** Generate a list of parties, `fee_payer_keypairs` contains a list of possible fee payers
  *)
val gen_list_of_parties_from :
     ?failure:failure
  -> ?max_other_parties:int
  -> fee_payer_keypairs:Signature_lib.Keypair.t list
  -> keymap:
       Signature_lib.Private_key.t Signature_lib.Public_key.Compressed.Map.t
  -> ?account_state_tbl:(Account.t * role) Account_id.Table.t
  -> ledger:Mina_ledger.Ledger.t
  -> ?protocol_state_view:Zkapp_precondition.Protocol_state.View.t
  -> ?vk:(Side_loaded_verification_key.t, State_hash.t) With_hash.Stable.V1.t
  -> ?length:int
  -> unit
  -> Parties.t list Quickcheck.Generator.t
