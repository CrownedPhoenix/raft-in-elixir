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
  @default_config %Config{
    members: [{:s1, :s1@BATDRIVE}, {:s2, :s2@BATDRIVE}, {:s3, :s3@BATDRIVE}]
  }

  #############
  # CALLBACKS #
  #############

  def start_link(name) do
    GenStateMachine.start_link(__MODULE__, {:follower, name}, name: name)
  end

  def stop(name) do
    GenStateMachine.stop(name)
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

  def follower(:cast, %RequestVote{} = req, state) do
    Logger.info("#{state.me} recieved #{inspect(req)}")

    new_state = State.handle_requestvote(state, req)

    RPC.broadcast([
      {
        req.from,
        %RequestVoteResp{
          from: new_state.me,
          term: new_state.currentTerm,
          voteGranted: new_state.votedFor == req.from
        }
      }
    ])

    if new_state.votedFor == req.from do
      {:repeat_state, new_state}
    else
      {:keep_state, new_state}
    end
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
      |> State.increment_term()
      |> State.reset_votes()
      |> State.vote_for(state.me)

    Logger.info("#{state.me} Starting election for term #{new_state.currentTerm}.")

    RPC.broadcast(
      Enum.map(Enum.reject(state.peers, &(elem(&1, 0) == state.me)), fn peer ->
        {peer,
         %RequestVote{
           from: state.me,
           term: state.currentTerm,
           lastLogIndex: length(state.log) - 1,
           lastLogTerm: List.last(state.log)
         }}
      end)
    )

    {:next_state, :candidate, new_state, [election_timeout(state) | request_vote_timeouts(state)]}
  end

  def candidate(:cast, %RequestVote{} = req, state) do
    Logger.info("#{state.me} recieved #{inspect(rsp)}")
    new_state = State.handle_requestvote(state, req)

    RPC.broadcast([
      {
        req.from,
        %RequestVoteResp{
          from: new_state.me,
          term: new_state.currentTerm,
          voteGranted: new_state.votedFor == req.from
        }
      }
    ])

    if new_state.votedFor == req.from do
      {:next_state, :follower, new_state}
    else
      {:keep_state, new_state}
    end
  end

  def candidate(:cast, %RequestVoteResp{} = rsp, state) do
    cond do
      State.has_voted?(state, rsp.from) ->
        :keep_state_and_data

      rsp.term >= state.currentTerm ->
        new_state = State.mark_voted(state, rsp.from)

        cond do
          rsp.voteGranted and rsp.term == state.currentTerm ->
            new_state = State.increment_vote_count(new_state)

            if new_state.voteCount >= State.majority(state) do
              {:next_state, :leader, new_state, [stop_peer_timeout(rsp.from)]}
            else
              {:keep_state, new_state, [stop_peer_timeout(rsp.from)]}
            end

          rsp.term > state.currentTerm ->
            new_state = State.update_term(new_state, rsp.term)
            {:next_state, :follower, new_state, [stop_peer_timeout(rsp.from)]}

          true ->
            {:keep_state, new_state, [stop_peer_timeout(rsp.from)]}
        end

      true ->
        :keep_state_and_data
    end
  end

  def candidate({:timeout, name}, data, state) do
    Logger.info("#{state.me} Timeout received.")

    RPC.broadcast([
      {name,
       %RequestVote{
         from: state.me,
         term: state.currentTerm,
         lastLogIndex: length(state.log) - 1,
         lastLogTerm: List.last(state.log)
       }}
    ])

    :keep_state_and_data
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
    timeout = state.config.heartbeat_timeout

    state.peers
    |> Enum.reject(&(elem(&1, 0) == state.me))
    |> Enum.map(fn name ->
      {{:timeout, name}, Enum.random(timeout..(2 * timeout)), {}}
    end)
  end

  def stop_peer_timeouts(state) do
    Enum.map(state.peers, fn name ->
      {{:timeout, name}, :cancel}
    end)
  end

  def stop_peer_timeout(state, peer) do
    {{:timeout, peer}, :cancel}
  end
end
