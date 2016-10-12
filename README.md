# TS

TransportScheduler application.
GenStateMachine for station FSM and GenServer for IPC.
Edeliver using Exrm for building releases and deployment.
Travis for continuous integration.

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

Run the following commands to compile:  
`cd TransportScheduler`  
`mix deps.get`  
`mix compile`  
`mix test`  

Run the following commands to deploy (currently server and user are localhost):   
`mix edeliver build release`   
`mix edeliver deploy release`   

Run the following commands to start application:   
`mix edeliver start`   

Visit `http://localhost:8880/schedule?stn_code=1` for testing API   

