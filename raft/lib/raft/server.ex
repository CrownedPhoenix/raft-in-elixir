defmodule Raft.Server do
  use GenStateMachine, callback_mode: [:state_functions, :state_enter]

  require Logger

  alias Raft.{
    State,
    Config,
    RPC,
    RPC.AppendEntries,
    RPC.AppendEntriesResp,
    RPC.RequestVote,
    RPC.RequestVoteResp
  }

  @initialstate %State{}
  @default_config %Config{members: [:s1, :s2, :s3]}

  #############
  # CALLBACKS #
  #############

  def start_link({name}) do
    GenStateMachine.start_link(__MODULE__, {:follower, name})
  end

  def init({:follower, name}) do
    cfg = @default_config
    state = %{@initialstate | me: name, config: cfg, peers: cfg.members}
    {:ok, :follower, state, []}
  end

  def follower(:enter, old_state, state) do
    Logger.info("#{state.me} Entering follower state.")
    new_state = State.reset_votes(state)
    {:next_state, :follower, new_state, [election_timeout(state) | stop_peer_timeouts(state)]}
  end

  def follower({:timeout, name}, data, state) do
    Logger.info("#{state.me} Timeout received.")
    {:next_state, :follower, state, []}
  end

  def follower(:state_timeout, data, state) do
    Logger.info("#{state.me} State timeout (follower) recieved.")
    {:next_state, :candidate, state}
  end

  def candidate(:enter, old_state, state) do
    Logger.info("#{state.me} Entering candidate state.")

    new_state =
      state
      |> State.reset_votes()
      |> State.vote_for(state.me)

    RPC.broadcast(
      Enum.map(Enum.reject(state.peers, &(&1 == state.me)), fn peer ->
        {peer,
         %RequestVote{
           term: state.currentTerm,
           candidateId: state.me,
           lastLogIndex: length(state.log) - 1,
           lastLogTerm: List.last(state.log)
         }}
      end)
    )

    {:next_state, :candidate, new_state, [election_timeout(state) | request_vote_timeouts(state)]}
  end

  def candidate({:timeout, name}, data, state) do
    Logger.info("#{state.me} Timeout received.")
    {:next_state, :follower, state, []}
  end

  def candidate(:state_timeout, data, state) do
    Logger.info("#{state.me} State timeout (candidate) recieved.")
    {:repeat_state, state}
  end

  ###########
  # HELPERS #
  ###########
  def election_timeout(state) do
    {:state_timeout, state.config.election_timeout, nil}
  end

  def request_vote_timeouts(state) do
    state.peers
    |> Enum.reject(&(&1 == state.me))
    |> Enum.map(fn name ->
      {{:timeout, name}, state.config.heartbeat_timeout, {}}
    end)
  end

  def stop_peer_timeouts(state) do
    Enum.map(state.peers, fn name ->
      {{:timeout, name}, :cancel}
    end)
  end
end
