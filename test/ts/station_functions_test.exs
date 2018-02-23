defmodule Station.FunctionsTest do
	@moduledoc"""
	Test module for station functions
	for computing congstion delay for a particular
	function
	"""

	use ExUnit.Case, async: true

	# Test 1

	# congestion_delay = delay * factor
	test "Check compute_congestion_delay1" do
		delay = 10
		factor = 0.5
		cd = Station.Functions.compute_congestion_delay1(delay, factor)

		assert cd == 5.0
	end

	# Test 2

	# congestion_delay = delay * factor + 0.2
	test "Check compute_congestion_delay2" do
		delay = 10
		factor = 0.5
		cd = Station.Functions.compute_congestion_delay2(delay, factor)

		assert cd == 5.2
	end

	# Test 3

	# congestion_delay = delay * factor * factor
	test "Check compute_congestion_delay3" do
		delay = 10
		factor = 0.5
		cd = Station.Functions.compute_congestion_delay3(delay, factor)

		assert cd == 2.5
	end

	# Test 4

	# Check if the correct congestion delay function is being used
	test "Check selection function" do
		delay = 10
		factor = 0.5

		# Choose compute_congestion_delay1
		choose_fn = 1
		cd1 = Station.Functions.func(choose_fn)
		cd = Station.Functions.compute_congestion_delay1(delay, factor)
		assert cd1.(delay, factor) == cd

		# Choose compute_congestion_delay2
		choose_fn = 2
		cd2 = Station.Functions.func(choose_fn)
		cd = Station.Functions.compute_congestion_delay2(delay, factor)
		assert cd2.(delay, factor) == cd

		# Choose compute_congestion_delay3
		choose_fn = 3
		cd3 = Station.Functions.func(choose_fn)
		cd = Station.Functions.compute_congestion_delay3(delay, factor)
		assert cd3.(delay, factor) == cd
	end
end
