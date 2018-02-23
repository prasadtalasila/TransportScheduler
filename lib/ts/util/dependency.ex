defmodule Util.Dependency do
	@moduledoc """
	This module defines the format for the struct that contains all the
	dependencies of a Stations.
	"""
	defstruct registry: nil, collector: nil, station: Station,
	itinerary: Itinerary
end
