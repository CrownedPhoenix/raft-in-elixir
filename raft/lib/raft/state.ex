defmodule Raft.State do
  defstruct peers: [],
            me: nil,
            currentTerm: 0,
            votedFor: nil,
            commitIndex: 0,
            lastApplied: 0,
            nextIndex: [],
            matchIndex: [],
            voteCount: 0,
            voted: [],
            config: nil
end
