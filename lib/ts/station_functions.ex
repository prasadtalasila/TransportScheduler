defmodule StationFunctions do

  def compute_congestion_delay1(delay, factor) do
    congestionDelay = delay * factor
  end
  def compute_congestion_delay2(delay, factor) do
    congestionDelay = delay * factor + 0.2
  end
  def compute_congestion_delay3(delay, factor) do
    congestionDelay = delay * factor * factor
  end

  def func(choose_fn) do
    Map.get(
      %{
	1 => fn (delay, factor) -> compute_congestion_delay1(delay, factor) end,
	2 => fn (delay, factor) -> compute_congestion_delay2(delay, factor) end,
	3 => fn (delay, factor) -> compute_congestion_delay3(delay, factor) end
      },
      choose_fn)
  end

end
