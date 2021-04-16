defmodule Raft.LogEntry do
  @enforce_keys [:term, :entry]
  defstruct [:term, :entry]
end
