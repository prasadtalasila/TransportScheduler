# TS

TransportScheduler using GenStateMachine for station FSM and GenServer for IPC.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

* Add `fsm`, `exactor`, `gen_state_machine` and `maru` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:fsm, "~> 0.2.0"}, {:exactor, "~> 2.1.0"}, {:gen_state_machine, "~> 1.0"}, {:maru, "~> 0.2.8"}]
end
```

* Ensure `gen_state_machine`, `logger` and `maru` are started before your application:

```elixir
def application do
  [applications: [:gen_state_machine, :logger, :maru]]
end
```

* Finally, make sure that `escript` is included in `mix.exs`:

```elixir
def escript do
    [main_module: Main]
end
```

## Usage

Run the following commands:  
`cd TransportScheduler`  
`mix deps.get`  
`mix compile`  
`mix test`  
`mix escript.build`  
`./ts`  
