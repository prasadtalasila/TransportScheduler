defmodule StationFunctions do
	@moduledoc """
	Module listing possible functions to use to compute congestion_delay value
	based on delay and some factor for multiplication. Based on the choice of
	function when Station local variables are being updated, a different
	mathematical formula gives the final congestion delay value from the original
	base delay value and the factor value.
	"""

	@doc """
	Congestion computation function 1.
	Computes congestion_delay=delay*factor.
	### Parameters
	delay
	factor
	### Return values
	Returns congestion_delay value.
	"""
	def compute_congestion_delay1(delay, factor) do
		_ = delay * factor
	end

	@doc """
	Congestion computation function 2.
	Computes congestion_delay=delay*factor+0.2.
	### Parameters
	delay
	factor
	### Return values
	Returns congestion_delay value.
	"""
	def compute_congestion_delay2(delay, factor) do
		_ = delay * factor + 0.2
	end

	@doc """
	Congestion computation function 3.
	Computes congestion_delay=delay*factor*factor.
	### Parameters
	delay
	factor
	### Return values
	Returns congestion_delay value.
	"""
	def compute_congestion_delay3(delay, factor) do
		_ = delay * factor * factor
	end

	@doc """
	Chooses congestion computation function.
	### Parameters
	choose_fn
	### Return values
	Returns congestion_delay value based on function chosen to compute it.
	"""
	def func(choose_fn) do
		# appropriate function is called using choose_fn value as Map key
		Map.get(
			%{1 => fn (delay, factor) -> compute_congestion_delay1(delay, factor) end,
			2 => fn (delay, factor) -> compute_congestion_delay2(delay, factor) end,
			3 => fn (delay, factor) -> compute_congestion_delay3(delay, factor) end},
			choose_fn)
	end

end