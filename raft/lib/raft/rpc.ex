defmodule Raft.RPC do
  require Logger

  defmodule AppendEntries do
    @enforce_keys [:term, :leaderId, :prevLogIndex, :prevLogTerm, :entries, :leaderCommit]
    defstruct [:term, :leaderId, :prevLogIndex, :prevLogTerm, :entries, :leaderCommit]
  end

  defmodule AppendEntriesResp do
    @enforce_keys [:term, :success, :closestIndex]
    defstruct [:term, :success, :closestIndex]
  end

  defmodule RequestVote do
    @enforce_keys [:term, :candidateId, :lastLogIndex, :lastLogTerm]
    defstruct [:term, :candidateId, :lastLogIndex, :lastLogTerm]
  end

  defmodule RequestVoteResp do
    @enforce_keys [:term, :voteGranted]
    defstruct [:term, :voteGranted]
  end

  def broadcast(msgs) do
    IO.inspect(msgs)
    Enum.each(msgs, fn {to, rpc} ->
      Logger.info(["Call to: #{to}; ", inspect(rpc)])
      GenStateMachine.cast(to, rpc)
    end)
  end
end
