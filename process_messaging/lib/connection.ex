defmodule Util.Connection do
	@moduledoc """
	This module defines the format of a Connection between two Stations.
	"""
	defstruct vehicleID: nil, src_station: nil, mode_of_transport: nil,
	dst_station: nil, dept_time: nil, arrival_time: nil
end
