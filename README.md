# TS

TransportScheduler using GenStateMachine for station FSM and GenServer for IPC. Edeliver using Exrm for building releases and deployment.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

1. Add `ts` to your list of dependencies in `mix.exs`:

```elixir
def deps do
[{:ts, "~> 0.1.0"}]
end
```

2. Ensure `ts` is started before your application:

```elixir
def application do
[applications: [:ts]]
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
