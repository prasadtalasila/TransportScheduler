# Module to test API

defmodule APITest do
  use ExUnit.Case, async: true
  use Maru.Test, for: API

  setup do
    conn=build_conn()|>put_req_header("content-type", "application/json")
    |>put_plug(Plug.Parsers, parsers: [:json], pass: ["*/*"], json_decoder: Poison)
    {:ok, %{conn: conn}}
  end

  test "Return welcome message" do
    assert "Welcome to TransportScheduler API\n" == get("/api")|>text_response
  end

  test "Returns schedule", %{conn: conn} do
    get("/api")
    schedule1="[{\"vehicleID\":\"16590\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":1200,\"arrival_time\":2700},{\"vehicleID\":\"16536\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":3600,\"arrival_time\":5880},{\"vehicleID\":\"16535\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":5700,\"arrival_time\":7680},{\"vehicleID\":\"12781\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":10020,\"arrival_time\":11760},{\"vehicleID\":\"16589\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":12900,\"arrival_time\":14580},{\"vehicleID\":\"16210\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":15300,\"arrival_time\":17040},{\"vehicleID\":\"16506\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":15300,\"arrival_time\":17040},{\"vehicleID\":\"16508\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":15300,\"arrival_time\":17040},{\"vehicleID\":\"17311\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":15300,\"arrival_time\":17040},{\"vehicleID\":\"17313\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":15300,\"arrival_time\":17040},{\"vehicleID\":\"17310\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":11,\"dept_time\":15300,\"arrival_time\":18420},{\"vehicleID\":\"17301\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":18900,\"arrival_time\":20820},{\"vehicleID\":\"12726\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":27000,\"arrival_time\":28680},{\"vehicleID\":\"12777\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":30060,\"arrival_time\":31800},{\"vehicleID\":\"12778\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":38400,\"arrival_time\":40140},{\"vehicleID\":\"12079\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":41520,\"arrival_time\":43140},{\"vehicleID\":\"11006\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":46200,\"arrival_time\":48240},{\"vehicleID\":\"11022\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":46200,\"arrival_time\":48240},{\"vehicleID\":\"11036\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":46200,\"arrival_time\":48240},{\"vehicleID\":\"11005\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":51840,\"arrival_time\":53280},{\"vehicleID\":\"11021\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":51840,\"arrival_time\":53280},{\"vehicleID\":\"11035\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":51840,\"arrival_time\":53280},{\"vehicleID\":\"12080\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":55800,\"arrival_time\":57120},{\"vehicleID\":\"12725\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":68400,\"arrival_time\":70500},{\"vehicleID\":\"16209\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":70080,\"arrival_time\":72300},{\"vehicleID\":\"16505\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":70080,\"arrival_time\":72300},{\"vehicleID\":\"16507\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":70080,\"arrival_time\":72300},{\"vehicleID\":\"17309\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":8,\"dept_time\":75000,\"arrival_time\":77040},{\"vehicleID\":\"12782\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":79320,\"arrival_time\":81180},{\"vehicleID\":\"17314\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":10,\"dept_time\":79320,\"arrival_time\":81180},{\"vehicleID\":\"17312\",\"src_station\":9,\"mode_of_transport\":\"train\",\"dst_station\":11,\"dept_time\":79320,\"arrival_time\":82200}]"
    assert schedule1==conn|>get("/api/station/schedule?station_code=9&date=11-2-2017")|>text_response
    assert "[]"==conn|>get("/api/station/schedule?station_code=2264&date=11-2-2017")|>text_response
    assert %{"error"=>"Invalid data"}==conn|>get("/api/station/schedule?station_code=2265&date=11-2-2017")|>json_response
    assert %{"error"=>"Invalid data"}==conn|>get("/api/station/schedule?station_code=-34&date=11-2-2017")|>json_response
    API.remove(:NC)
  end

  test "add new entry to schedule, update existing entry in schedule", %{conn: conn} do
    get("/api")
    assert "New Schedule added!\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID": "I5-1234_A320", "src_station": 135, "dst_station": 453, "dept_time": 12300, "arrival_time": 14000, "mode_of_transport": "flight"}}))|>post("/api/station/schedule/add")|>text_response
    assert "New Schedule added!\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID": "12367", "src_station": 523, "dst_station": 918, "dept_time": 23000, "arrival_time": 76720, "mode_of_transport": "train"}}))|>post("/api/station/schedule/add")|>text_response
    assert "New Schedule added!\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID": "1100234", "src_station": 1267, "dst_station": 412, "dept_time": 12300, "arrival_time": 94000, "mode_of_transport": "bus"}}))|>post("/api/station/schedule/add")|>text_response
    assert %{"error"=>"Invalid data"}==conn|>put_body_or_params(~s({"entry": {"vehicleID": "11034", "src_station": 4267, "dst_station": 4122, "dept_time": 27620, "arrival_time":93700, "mode_of_transport": "train"}}))|>post("/api/station/schedule/add")|>json_response
    assert "Schedule Updated!\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID":"11043", "src_station":115, "mode_of_transport":"train", "dst_station":294, "dept_time":51200, "arrival_time":64000}}))|>put("/api/station/schedule/update")|>text_response
    assert "Schedule Updated!\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID":"G8-355_A320", "src_station":928, "mode_of_transport":"flight", "dst_station":1634, "dept_time":34500, "arrival_time":46200}}))|>put("/api/station/schedule/update")|>text_response
    assert %{"error"=>"Invalid data"}==conn|>put_body_or_params(~s({"entry": {"vehicleID": "3401101", "src_station": 2378, "dst_station": 0, "dept_time": 87600, "arrival_time": 24000, "mode_of_transport": "bus"}}))|>put("/api/station/schedule/update")|>json_response
    #assert "Vehicle not found\n"==conn|>put_body_or_params(~s({"entry": {"vehicleID": "11002", "src_station": 7, "dst_station": 4, "dept_time": 12300, "arrival_time": 14000, "mode_of_transport": "flight"}}))|>put("/api/station/schedule/update")|>text_response
    API.remove(:NC)
  end

  test "returns state, updates state", %{conn: conn} do
    get("/api")
    locVars1="{\"disturbance\":\"no\",\"delay\":1.84,\"congestionDelay\":5.5200000000000005,\"congestion\":\"high\"}"
    assert locVars1==conn|>get("/api/station/state?station_code=565")|>text_response
    locVars2="{\"disturbance\":\"no\",\"delay\":0.38,\"congestionDelay\":0.76,\"congestion\":\"low\"}"
    assert locVars2==conn|>get("/api/station/state?station_code=778")|>text_response
    assert %{"error"=>"Invalid data"}==conn|>get("/api/station/state?station_code=2924")|>json_response
    assert "State Updated!\n"==conn|>put_body_or_params(~s({"station_code": 4, "local_vars": {"congestion": "low", "delay": 0.45, "disturbance": "yes"}}))|>put("/api/station/state/update")|>text_response
    assert "State Updated!\n"==conn|>put_body_or_params(~s({"station_code": 1632, "local_vars": {"congestion": "high", "delay": 0.27, "disturbance": "no"}}))|>put("/api/station/state/update")|>text_response
    assert %{"error"=>"Invalid data"}==conn|>put_body_or_params(~s({"station_code": 0, "local_vars": {"congestion": "high", "delay": 0.194, "disturbance": "yes"}}))|>put("/api/station/state/update")|>json_response
    assert "New Station created!\n"==conn|>put_body_or_params(~s({"local_vars": {"congestion": "none", "delay": 3.14, "disturbance": "no"}, "schedule": {"vehicleID": 69, "src_station": 2500, "dst_station": 18, "dept_time": 0, "arrival_time": 32300, "mode_of_transport": "chariot"}, "station_code": 2500, "station_name": "Atlantis"}))|>post("/api/station/create")|>text_response
    API.remove(:NC)
  end

end
