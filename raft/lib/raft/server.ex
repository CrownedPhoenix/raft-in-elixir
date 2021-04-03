defmodule Raft.Server do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger

  def init(args) do
    # TODO: Whatever initialization needs to be done for the server.
    {:ok, :follower, {:state, 0}, []}
  end

  def follower(:enter, state, data) do
    Logger.info("Entering follower state.")
    {:next_state, :follower, data, [{{:timeout, :one}, 500, {1}}, {{:timeout, :two}, 3000, {2}}]}
  end

  def follower({:timeout, :two}, data, state) do
    Logger.info("Cancelling timeout two")
    {:next_state, :follower, data, [{{:timeout, :two}, :cancel}]}
  end

  def follower({:timeout, name}, data, state) do
    Logger.info("Timeout received.")
    IO.inspect({name, state, data})
    Process.sleep(5000)
    {:next_state, :follower, data, [{{:timeout, :two}, 5000, {3}}]}
  end
end
