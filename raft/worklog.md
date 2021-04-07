## 03/23/2021 (2.75hr)
- READ https://elixirschool.com/en/lessons/advanced/otp-distribution/
- READ https://www.monkeyvault.net/distributed-consensus-and-other-stories/
- FOUND https://akoutmos.com/post/actor-model-genserver-app/
- FOUND https://pragprog.com/titles/jgotp/designing-elixir-systems-with-otp/
- FOUND https://www.youtube.com/watch?v=CJT8wPnmjTM
- READ https://www.toptal.com/elixir/process-oriented-programming-elixir-and-otp
- FOUND (Previously Read) https://elixirschool.com/en/lessons/advanced/otp-concurrency/

Resources:
- An Existing Raft Impl in Elixir
  *  https://hexdocs.pm/raft/Raft.html
  *  https://github.com/toniqsystems/raft
- Another Raft Impl
  *  https://github.com/rabbitmq/ra
- PURCHASED **"The Little Elixir & OTP Guidebook"**

## 03/24/2021 (1.25hr)
- READ https://www.youtube.com/watch?v=CJT8wPnmjTM (from 03/23/2021)

Resources:
-  READ (started) https://hexdocs.pm/gen_state_machine/GenStateMachine.html
    - `toniqsystems/raft` makes use of this module

## 03/29/2021 (1.5hr)
- Got basic GenStateServer running.
    - [ ] **TODO:** Fill out remaining state functions.
- READ (continued) `GenStateMachine`
- READ about Elixir.Task; Task.async spawns a new process.
    I can use Tasks to send timeout messages back to the Raft.Server
    which will be handled atomically and in some total order.

## 03/30/2021 (0.75hr)
- READ (continued) `GenStateMachine`
- READ (started) http://erlang.org/doc/man/gen_statem.html
- READ (started) http://erlang.org/doc/design_principles/statem.html
    - **NOTE:** Erlang's statem module/behavior supports `transition actions` that
      will help with managing state timeouts.

## 03/31/2021 (0.5hr)
- Played around with `transition actions` to figure out how to make use of them

## 04/01/2021 (1hr)
- READ (continued) `erlang.org/doc/design_principles/statem.html`

## 04/03/2021 (2.5hr)
- **NOTE:** If a timeout expires during another event-handler, if it is cancelled
    or reset in that handler, the :timeout handler will not fire. This is
    VERY important as it means I don't have to worry about the problem
    that caused me to create TaskCapsules in my Golang implementation.
- [x] **TODO:** Create a state diagram for Raft following the pattern at 
    `http://erlang.org/doc/design_principles/statem.html#example`
      * Not complete. I realized I don't need it complete because I'm confident that 
        the remainder can be done with `GenStateServer`

## 04/05/2021 (1.5hr)
- Spent some time thinking about implementation questions:
    * Can I sidestep worrying about configuration transitions?  
      __Yes. Just make the Network allow named endpoints. All peers start with the
      same list of neighbor names. If one peer starts before another, the Network will
      just timeout the response until the peer has registered itself on the network 
      under its specified name.__
    * Are there any improvements on`toniqsystems` implementation that I can consider?  
      __Yes. `toniqsystems` uses a single timeout for each state. I've figured out how
      to utilize mutliple timeouts per state so that a leader can have independent timeouts
      for each of its followers.__  
      __Additionally, the unreliable network abstraction seems like it would be a unique
      improvement if I can get to that.__
- Read over some more of the high level details of `toniqsystems` implementation. Specifically regarding:
    * Initialization
    * Keeping state data
    * Configuration / Configuration changes
    * Config (startup)
- Learned some Elixir sugar I didn't know:
    * Anonymous functions can be written without parentheses.  
      ```elixir
      def foo(num, func) do
        func.(num)
      end

      foo(5, & &1 + 1) # 6
      ```
    * Alternative to updating existing key in map.
      ```elixir
      a = %{foo: 1, bar: 2}
      %{a | foo: 3 } # %{foo: 3, bar: 2}
      ```
## 04/06/2021 (1.75hr)
- Added a few more handlers to Raft.Server
- Looked over the first two of `toniqsystems` commits to get a feel for where they started out. I wanted to get an intuition for the early phase of development, specifically regarding project layout.
    * **NOTE:** 
       - Test driven development. I ought to start with some basic tests - it will help me with project organization I think.
       - Config module appeared pretty early.
- __ROADBLOCK:__ The biggest roadblock I'm having right now is project organization. I already have my original Golang implementation and I understand how I can use GenStateMachine to implement the event handlers for the various cases (many of which I already drafted in the [diagram](../RaftStateDiagram.jpg) I made. So I need to get more solid on the layout I want to employ.

## 04/07/2021 (1.5hr)
- Made some updates to Raft.Server
- Tried to simplify stuff where possible
- Got a basic :follower running with a state timeout.
- **TODO:** Try to just get leader election up and running on a hardcoded cluster.

