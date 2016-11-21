# TS

TransportScheduler application.
GenStateMachine for station FSM and GenServer for IPC.
Edeliver using Exrm for building releases and deployment.
Travis for continuous integration.
Maru provides a RESTful API implementation.

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
```
cd TransportScheduler
mix deps.get
mix compile
mix test
```

Run the following commands to deploy (currently server and user are localhost):   
```
mix edeliver build release
mix edeliver deploy release
```

Run the following command to start application:   
```
mix edeliver start
```

Issue the following cURL command for initialisation of the network:
```
curl http://localhost:8880/api
```

For testing the API, following cURL commands are issued to:

1. Obtain Schedule of a Station:  
```
curl -X GET 'http://localhost:8880/api/station/schedule?station_code=%STATION_CODE%&date=%DATE%'
```  
where %STATION_CODE% is a positive integer indicating the station code of the source and %DATE% is the date of travel in the format 'dd-mm-yyyy'.

2. Obtain State of a Station:  
```
curl -X GET 'http://localhost:8880/api/station/state?station_code=%STATION_CODE%'
```  
where %STATION_CODE% is a positive integer indicating the required station code.
