defmodule Raft.State do
  alias Raft.{LogEntry}

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
            log: [%LogEntry{term: 0, entry: :head}]

  def increment_term(state) do
    %{state | currentTerm: state.currentTerm + 1}
  end

  def update_term(state, new_term) do
    %{state | currentTerm: new_term}
  end

  def reset_votes(state) do
    %{
      state
      | voteCount: 0,
        voted: Enum.map(state.voted, fn {peer, _} -> {peer, false} end) |> Enum.into(%{})
    }
  end

  def increment_vote_count(state) do
    %{state | voteCount: state.voteCount + 1}
  end

  def vote_for(state, peer) do
    %{state | votedFor: peer}
  end

  def mark_voted(state, member) do
    Map.put(state.voted, member, true)
  end

  def has_voted?(state, member) do
    Map.get(state.voted, member, false)
  end

  def handle_requestvote(state, %RequestVote{} = req) do
    cond do
      req.term < state.currentTerm ->
        state

      not State.can_vote_for?(state, req.candidateId, req.term) ->
        state

      State.is_more_up_to_date_than?(state, req.lastLogTerm, req.lastLogIndex) ->
        %{state | currentTerm: req.term, votedFor: req.from}

      req.term > state.currentTerm ->
        %{state | currentTerm: req.term}

      true ->
        state
    end
  end

  def can_vote_for?(state, candidate_id, candidate_term) do
    not has_voted?(state, state.me) or state.votedFor == candidate_id or
      state.term > candidate_term
  end

  def is_more_up_to_date_than?(state, last_log_term, last_log_index) do
    my_last_log_index = length(state.log) - 1
    last_entry = State.lastLogEntry(state)

    last_entry.term > last_log_term or
      (last_entry.term == last_log_term and my_last_log_index > last_log_index)
  end
end
