defmodule SB do
  def loop(pid, str) do
    data = Registry.lookup(pid, str)
    loop(pid, str)
  end

  def driver(pid, str) do
    Registry.addProcess(pid, self() )
    loop(pid, str)
  end

	def benchmark do
		cases = [0, 1, 2, 4, 8, 16, 32, 64]
		procs = [1, 2, 3, 4, 5, 6, 10, 100, 1000, 10_000]
		IO.puts "Starting benchmark"
		IO.write "| "
		for i <- cases do
			IO.write "| #{i} "
		end
		IO.puts "|"
		IO.write "| --- "
		for i <- cases do
			IO.write "| --- "
		end
		IO.puts "|"
		for i <- procs do
			IO.write "| #{i} processes "
			for j <- cases do
				itinerary = Util.Itinerary.new(j)
				val = runner(i, itinerary)
				IO.write "| #{val} "
			end
			IO.puts "|"
		end
		IO.puts "Ending benchmark"
	end

  def runner(n, str) do
    {:ok, pid} = Registry.start_link
    spawner(n, str, pid)
    Registry.start_timer(pid)
    :timer.sleep(31_000)
    val = Registry.getCount(pid)
    Registry.stop(pid)
		val
  end

  def spawner(n, str, pid) when n > 0 do
    spawn(SB,:driver,[pid, str])
    spawner(n-1, str, pid)
  end

  def spawner(n, str, pid) do
  end
end
