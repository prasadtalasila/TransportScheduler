# TS

TransportScheduler using functional FSM for station and GenServer for registry.

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
cd TransportScheduler  
mix deps.get  
mix compile  
mix test  
