defmodule Raft.RPC do
  require Logger

  defmodule AppendEntries do
    @enforce_keys [:from, :term, :leaderId, :prevLogIndex, :prevLogTerm, :entries, :leaderCommit]
    defstruct [:from, :term, :leaderId, :prevLogIndex, :prevLogTerm, :entries, :leaderCommit]
  end

  defmodule AppendEntriesResp do
    @enforce_keys [:from, :term, :success, :closestIndex]
    defstruct [:from, :term, :success, :closestIndex]
  end

  defmodule RequestVote do
    @enforce_keys [:from, :term, :lastLogIndex, :lastLogTerm]
    defstruct [:from, :term, :lastLogIndex, :lastLogTerm]
  end

  defmodule RequestVoteResp do
    @enforce_keys [:from, :term, :voteGranted]
    defstruct [:from, :term, :voteGranted]
  end

  def broadcast(msgs) do
    Enum.each(msgs, fn {to, rpc} ->
      Logger.info(["Call to: #{inspect(to)}; ", inspect(rpc)])
      GenStateMachine.cast(to, rpc)
    end)
  end
end
