defmodule Util.Query do
	@moduledoc """
	This module defines the format of a query.
	"""
	defstruct qid: nil, src_station: nil, dst_station: nil, arrival_time: nil,
	end_time: nil
end
