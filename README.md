# TS

[![Build Status](https://travis-ci.org/prasadtalasila/TransportScheduler.svg?branch=master)](https://travis-ci.org/prasadtalasila/TransportScheduler) [![Coverage Status](https://coveralls.io/repos/github/prasadtalasila/TransportScheduler/badge.svg?branch=master)](https://coveralls.io/github/prasadtalasila/TransportScheduler?branch=master) [![Code Climate](https://codeclimate.com/github/prasadtalasila/TransportScheduler/badges/gpa.svg)](https://codeclimate.com/github/prasadtalasila/TransportScheduler)

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
```bash
cd TransportScheduler
mix deps.get
mix compile
mix test
```

Run the following commands to deploy (currently server and user are localhost):   
```bash
mix edeliver build release
mix edeliver deploy release
```

Run the following command to start application:   
```bash
mix edeliver start
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
