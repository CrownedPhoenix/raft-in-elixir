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
    - **TODO:** Fill out remaining state functions.
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
