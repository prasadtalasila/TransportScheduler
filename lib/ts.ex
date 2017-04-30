defmodule TS do
	@moduledoc """
	The TransportScheduler application implements an Actor-based concurrent approach
	to allow interactive journey planning in multimodal public transit networks.

	Each transit station is modelled as an Actor. Concurrent itinerary search over
	transit schedules is possible by users. Itineraries obtained can be filtered
	based on user preference. Real-time update to timetables and station status is
	possible by local network managers.

	Uses Application.
	"""
	use Application

	@doc """
	This function is called when an the application is started using
	`Application.start/2`.

	This function should start the top-level process of the application (which should
	be the top supervisor of the application's supervision tree if the application
	follows the OTP	design principles around supervision).

	### Parameters
	start_type - defines how the application is started:
	- :normal - used if the startup is a normal startup or if the application is
	distributed and is started on the current node because of a failover from another
	mode and the application specification key :start_phases is :undefined.
	- {:takeover, node} - used if the application is distributed and is started on
	the current node because of a failover on the node node.
	- {:failover, node} - used if the application is distributed and is started on
	the current node because of a failover on node node, and the application
	specification key :start_phases is not :undefined.   

	start_args - arguments passed to the application in the :mod specification key.
	
	### Return values
	This function should either return {:ok, pid} or {:ok, pid, state} if startup
	is successful. pid should be the pid of the top supervisor. state can be an
	arbitrary term, and if omitted will default to [].
	"""
	def start(_type, _args) do
		TS.Supervisor.start_link
	end
end
