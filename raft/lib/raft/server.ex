defmodule Raft.Server do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger
  alias Raft.{State}

  @initialstate %State{}

  #############
  # CALLBACKS #
  #############

  def start_link({name}) do
    GenStateMachine.start_link(__MODULE__, {:follower, name})
  end

  def init({:follower, name}) do
    state = %{@initialstate | me: name}
    {:ok, :follower, state, []}
  end

  def follower(:enter, state, data) do
    Logger.info("Entering follower state.")
    {:next_state, :follower, data, follower_timeouts(state)}
  end

  def candidate(:enter, state, data) do
    Logger.info("Entering candidate state.")
    {:next_state, :candidate, state, data, [election_timeout(state) | request_vote_timeouts(state)]}
  end

  def follower({:timeout, name}, data, state) do
    Logger.info("Timeout received.")
    {:next_state, :follower, data, []}
  end

  def follower(:state_timeout, data, state) do
    Logger.info("State timeout (follower) recieved.")
    {:repeat_state, data}
  end

  def follower_timeouts(state) do
    [{:state_timeout, 1000, nil}]
  end
end
