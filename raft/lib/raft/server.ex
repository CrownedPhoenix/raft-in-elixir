defmodule Raft.Server do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger

  def init(args) do
    # TODO: Whatever initialization needs to be done for the server.
    {:ok, :follower, {}, []}
  end

  def follower(:enter, state, data) do
    Logger.info("Entering follower state.")
    {:next_state, :follower, data}
  end

end
