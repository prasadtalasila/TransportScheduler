# TS

TransportScheduler application dependencies:   
GenStateMachine for station FSM and GenServer for IPC.   
Maru for RESTful API implementation.   
Edeliver using Distillery for building releases and deployment.   

Other packages used:   
ExCoveralls for test coverage.   
ExProf for profiling.   
Credo for code quality.   


## Usage

Run the following commands to compile:
```bash
cd TransportScheduler
mix deps.get
mix compile
mix test
```

Run the following command to build a release:
```bash
mix release
```

Run the following command to run the application interactively:
```bash
_build/dev/rel/ts/bin/ts console
```

Issue the following cURL command for initialisation of the network:
```bash
curl http://localhost:8880/api
```

For testing the API, following cURL commands are issued to:

1. Obtain Schedule of a Station:  
```bash
curl -X GET 'http://localhost:8880/api/station/schedule?station_code=%STATION_CODE%&date=%DATE%'
```  
where `%STATION_CODE%` is a positive integer indicating the station code of the source and `%DATE%` is the date of travel in the format 'dd-mm-yyyy'.

2. Obtain State of a Station:  
```bash
curl -X GET 'http://localhost:8880/api/station/state?station_code=%STATION_CODE%'
```  
where `%STATION_CODE%` is a positive integer indicating the required station code.

Run the following commands to deploy (currently server and user are localhost): **UNTESTED**    
```bash
mix edeliver build release
mix edeliver deploy release
```

Run the following command to start application: **UNTESTED**   
```bash
mix edeliver start
```

## Interaction
```bash
iex>
```

