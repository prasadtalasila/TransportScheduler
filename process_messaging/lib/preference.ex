defmodule Util.Preference do
	@moduledoc """
	This module defines the format for the preferences in an itinerary.
	"""
	alias Util.Connection
	alias Util.Preference
	alias Util.Query
	defstruct day: 0, mode_of_transport: nil
end
