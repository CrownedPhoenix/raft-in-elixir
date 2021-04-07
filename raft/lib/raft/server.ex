defmodule Raft.Server do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger
  alias Raft.{State, Config}

  @initialstate %State{}
  @default_config %Config{members: [:s1, :s2, :s3]}

  #############
  # CALLBACKS #
  #############

  def start_link({name}) do
    GenStateMachine.start_link(__MODULE__, {:follower, name})
  end

  def init({:follower, name}) do
    state = %{@initialstate | me: name, config: @default_config}
    {:ok, :follower, state, []}
  end

  def follower(:enter, old_state, state) do
    Logger.info("Entering follower state.")
    {:next_state, :follower, state, [election_timeout(state)]}
  end

  def candidate(:enter, old_state, state) do
    Logger.info("Entering candidate state.")

    {:next_state, :candidate, state, [election_timeout(state) | request_vote_timeouts(state)]}
  end

  def follower({:timeout, name}, data, state) do
    Logger.info("Timeout received.")
    {:next_state, :follower, data, []}
  end

  def follower(:state_timeout, data, state) do
    Logger.info("State timeout (follower) recieved.")
    {:repeat_state, state}
  end

  def election_timeout(state) do
    {:state_timeout, state.config.election_timeout, nil}
  end

  def request_vote_timeouts(state) do
    []
  end
end
