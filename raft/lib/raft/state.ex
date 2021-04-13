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
            voted: %{},
            config: nil,
            log: [{:head}]

  def increment_term(state) do
    %{state | currentTerm: state.currentTerm + 1}
  end

  def reset_votes(state) do
    %{
      state
      | voteCount: 0,
        voted: Enum.map(state.voted, fn {peer, _} -> {peer, false} end) |> Enum.into(%{})
    }
  end

  def vote_for(state, peer) do
    %{state | votedFor: peer}
  end
end
