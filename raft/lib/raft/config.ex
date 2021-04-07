defmodule Raft.Config do
  defstruct election_timeout: 3_000, heartbeat_timeout: 300, members: []

  @type t :: %__MODULE__{
          election_timeout: non_neg_integer(),
          heartbeat_timeout: non_neg_integer(),
          members: [node()]
        }

end
