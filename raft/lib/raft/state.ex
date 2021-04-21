defmodule Raft.State do
  require Logger
  alias Raft.{LogEntry, RPC.RequestVote, RPC.RequestVoteResp, RPC.AppendEntries}

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
    %{state | voted: Map.put(state.voted, member, true)}
  end

  def has_voted?(state, member) do
    Map.get(state.voted, member, false)
  end

  def majority(state) do
    div(length(state.peers), 2) + 1
  end

  def prepare_append_entries(state, name) do
    entries =
      if state.nextIndex[name] >= length(state.log) do
        []
      else
        start = state.nextIndex[name]
        Enum.slice(state.log, start..length(state.log))
      end

    prevLogIndex = state.nextIndex[name] - 1

    %AppendEntries{
      from: state.me,
      term: state.currentTerm,
      prevLogIndex: prevLogIndex,
      prevLogTerm: state.log[prevLogIndex].term,
      entries: entries,
      leaderCommit: state.commitIndex
    }
  end

  def prepare_request_vote(state) do
    %RequestVote{
      from: state.me,
      term: state.currentTerm,
      lastLogIndex: length(state.log) - 1,
      lastLogTerm: List.last(state.log)
    }
  end

  def handle_request_vote(state, %RequestVote{} = req) do
    Logger.info("#{inspect(state.me)} -- #{inspect(state)} Handling requestvote #{inspect(req)}")

    cond do
      req.term < state.currentTerm ->
        Logger.info("#{inspect(state.me)} ignoring requestvote (lesser term)")
        state

      not can_vote_for?(state, req.from, req.term) ->
        Logger.info("#{inspect(state.me)} ignoring requestvote (cannot vote for)")
        state

      not is_more_up_to_date_than?(state, req.lastLogTerm, req.lastLogIndex) ->
        Logger.info("#{inspect(state.me)} voting for #{inspect(req.from)}")
        %{state | currentTerm: req.term, votedFor: req.from}

      req.term > state.currentTerm ->
        Logger.info("#{inspect(state.me)} ignoring requestvote (updating term)")
        %{state | currentTerm: req.term}

      true ->
        Logger.info("#{inspect(state.me)} ignoring requestvote (something else)")
        state
    end
  end

  def prepare_request_vote_resp(state, to) do
    %RequestVoteResp{
      from: state.me,
      term: state.currentTerm,
      voteGranted: state.votedFor == to
    }
  end

  def can_vote_for?(state, candidate_id, candidate_term) do
    not has_voted?(state, state.me) or state.votedFor == candidate_id or
      state.term > candidate_term
  end

  def is_more_up_to_date_than?(state, last_log_term, last_log_index) do
    my_last_log_index = length(state.log) - 1
    last_entry = List.last(state.log)

    last_entry.term > last_log_term or
      (last_entry.term == last_log_term and my_last_log_index > last_log_index)
  end
end
