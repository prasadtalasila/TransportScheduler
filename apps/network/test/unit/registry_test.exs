defmodule RegistryTest do
  @moduledoc """
  Tests the correctness of the functions in Registry
  """
  use ExUnit.Case, async: true
  alias Station.Registry, as: Registry

  test "Registering a process id in a group and perform lookup" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, pid} = MockServer.start_link()
    group = :group

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register group to pid mapping
    Registry.register_name(group, pid)

    assert :pg2.get_members(group) == [pid]

    Registry.stop(reg_pid)

  end

  test "Unregistering a process from a group" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, pid} = MockServer.start_link()
    group = :group

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register group to pid mapping
    Registry.register_name(group, pid)

    # Assert that the pid has been added to the group
    assert :pg2.get_members(group) == [pid]

    # Register group to pid mapping
    Registry.unregister_name(group, pid)

    assert :pg2.get_members(group) == []

    Registry.stop(reg_pid)
  end

  test "Process automatically is unregistered on its termination" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, pid} = MockServer.start_link()
    group = :group

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register group to pid mapping
    Registry.register_name(group, pid)

    # Assert that the pid has been added to the group
    assert :pg2.get_members(group) == [pid]

    # Terminate GenServer Process
    MockServer.stop(pid)

    wait_for_process_termination(pid)
    Process.sleep(100)

    assert :pg2.get_members(group) == []

    Registry.stop(reg_pid)
  end

  test "Unregistering a group" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, pid} = MockServer.start_link()
    group = :group

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register group to pid mapping
    Registry.register_name(group, pid)

    # Assert that the group exists
    assert is_list(:pg2.get_members(group))

    # Register group
    Registry.unregister_group(group)

    assert :pg2.get_members(group) == {:error, {:no_such_group, group}}

    Registry.stop(reg_pid)
  end

  test "Perform lookup after registering and unregistering a station" do
    # Start Registry Process
    #{:error, {:already_started, prev_pid}} = Registry.start_link()
    #Registry.stop(prev_pid)

    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, stn_pid} = MockServer.start_link()
    station_code = "station_code"
    group = {:station_code, station_code}

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register station
    Registry.register_station(station_code, stn_pid)

    assert Registry.lookup_code(station_code) == stn_pid

    # Unregister station
    Registry.unregister_station(station_code)

    assert Registry.lookup_code(station_code) == nil

    Registry.stop(reg_pid)
  end

  test "Perform lookup after registering and unregistering a station via termination of Station Process" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, stn_pid} = MockServer.start_link()
    station_code = "station_code"
    group = {:station_code, station_code}

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Register station
    Registry.register_station(station_code, stn_pid)

    assert Registry.lookup_code(station_code) == stn_pid

    # Terminate GenServer Process
    MockServer.stop(stn_pid)

    wait_for_process_termination(stn_pid)

    Process.sleep(10)

    assert Registry.lookup_code(station_code) == nil

    Registry.stop(reg_pid)
  end

  test "Check status for registered and unregistered query" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, qc_pid} = MockServer.start_link()
    qid = "qid"
    group = {:qid, qid}

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Since query is not registered yet it shouldn't be active
    refute Registry.check_active(qid)

    # Register station
    Registry.register_query(qid, qc_pid)

    # Assert that the query is active
    assert Registry.check_active(qid)

    # Unregister Query
    Registry.unregister_query(qid)

    # Assert that the query is inactive
    refute Registry.check_active(qid)

    Registry.stop(reg_pid)
  end

  test "Perform lookup for registered and unregistered query" do
    # Start Registry Process
    {:ok, reg_pid} = Registry.start_link()

    # Start a GenServer Process
    {:ok, qc_pid} = MockServer.start_link()
    qid = "qid"
    group = {:qid, qid}

    # Ensure that no group named group exists beforehand
    :pg2.delete(group)

    # Since query is not registered yet hence query id lookup should return nil
    assert Registry.lookup_query_id(qid) == nil

    # Register station
    Registry.register_query(qid, qc_pid)

    # Assert that query id lookup returns the pid of the registered
    # Query Collector process
    assert Registry.lookup_query_id(qid) == qc_pid

    # Unregister Query
    Registry.unregister_query(qid)

    # Assert that when the query is unregistered lookup on the
    # unregistered query returns nil
    assert Registry.lookup_query_id(qid) == nil

    Registry.stop(reg_pid)
  end

  def wait_for_process_termination(pid) do
    if Process.alive?(pid) do
      Process.sleep(10)
      wait_for_process_termination(pid)
    end
  end
end
