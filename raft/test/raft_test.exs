defmodule RaftTest do
  use ExUnit.Case
  doctest Raft

  test "start single node" do
    assert Raft.hello() == :world
  end
end
