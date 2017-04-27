defmodule Mix.Tasks.SyncBenchmark do
	@moduledoc """
	Helper module to run asynchronous benchmark
	"""
	use Mix.Task

	@doc """
	Runs the Synchronous Benchmark task for a single query.   
	
	### Return values
	If the task was not yet invoked, it runs the task and returns the result.
	If there is an alias with the same name, the alias will be invoked instead of the original task.
	If the task or alias were already invoked, it does not run them again and simply aborts with :noop.  
	"""
	def run(_args) do
		Mix.Task.run "app.start", []
		f=File.open! "data/test_sync.csv", [:append]
		IO.write(f, CSVLixir.write_row(["No.", "Source", "Destination",
			"Start time", "End time", "QPT (ms)"]))
		File.close(f)
		setup()
		{async_result, src, dst, start_time, cutoff_time}=process_request()
		if async_result !==:wrong do
			IO.puts "#{async_result} ms"
			f=File.open!("data/test_sync.csv", [:append])
			IO.write(f, CSVLixir.write_row([1, src, dst, start_time,
				cutoff_time, async_result]))
			File.close(f)
		end
	end

	@doc """
	Processes a single synchronous request.
	
	### Return values
	If the task was not yet invoked, it runs the task and returns the result.
	If there is an alias with the same name, the alias will be invoked instead of the original task.
	If the task or alias were already invoked, it does not run them again and simply aborts with :noop. 
	"""
	def process_request do
		issue()|>process_sync_request()
	end

	defp setup do
		:ok=:hackney_pool.start_pool(:first_pool, [timeout: 35_000,
			max_connections: 1000])
		HTTPoison.start
		IO.puts "Initialising network..."
		HTTPoison.get("http://localhost:8880/api", ["Accept": "application/json"],
			[recv_timeout: 10_000])
	end

	defp issue do
		src=:rand.uniform(2264)
		IO.puts "Source: #{src}"
		dst=:rand.uniform(2264)
		IO.puts "Destination: #{dst}"
		start_time=:rand.uniform(50_000)
		IO.puts "Start time: #{start_time}"
		url="http://localhost:8880/api/search?source="<>to_string(src)<>"&destina"<>
			"tion="<>to_string(dst)<>"&start_time="<>to_string(start_time)<>"&end_t"<>
			"ime="<>to_string(start_time+4*86_400)<>"&date=20-4-2017"
		cutoff_time=url|>HTTPoison.get(%{}, [recv_timeout: 30_500])|>elem(1)|>
			Map.get(:body)
		IO.puts "Cut-off time: #{cutoff_time}"
		if String.contains?(cutoff_time, "error") do
			{:wrong, src, dst, start_time, cutoff_time}
		else
			uri="http://localhost:8880/api/search?source="<>to_string(src)<>"&destina"<>
				"tion="<>to_string(dst)<>"&start_time="<>to_string(start_time)<>"&end_t"<>
				"ime="<>cutoff_time<>"&date=20-4-2017"
			:timer.sleep(2000)
			{uri, src, dst, start_time, cutoff_time|>String.to_integer}
		end
	end

	defp process_sync_request({uri, src, dst, start_time, cutoff_time}) do
		if uri !==:wrong do
			{time, _}=:timer.tc(fn->uri|>HTTPoison.get(
				["Content-Type": "application/json"], [recv_timeout: 30_500]) end)
			{Float.round(time/1000, 4), src, dst, start_time, cutoff_time}
		else
			{:wrong, src, dst, start_time, cutoff_time}
		end
	end

end
