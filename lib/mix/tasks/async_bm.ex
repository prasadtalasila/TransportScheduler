defmodule Mix.Tasks.AsyncBm do
	@moduledoc """
	Helper module to run asynchronous benchmarking.
	"""
	use Mix.Task

	@doc """
	Runs the AsyncBm task with the given args.

	
	### Parameters
	arg   
	
	### Return values
	If the task was not yet invoked, it runs the task and returns the result.
	If there is an alias with the same name, the alias will be invoked instead of the original task.
	If the task or alias were already invoked, it does not run them again and simply aborts with :noop. 
	"""
	def run(arg) do
		arg|>issue|>process_async_requests
	end


	@doc """
	Initialises the network using HHTPoison for http://localhost:8880/api.
	"""
	def setup do
		:ok=:hackney_pool.start_pool(:first_pool, [timeout: 35_000,
			max_connections: 1000])
		HTTPoison.start
		IO.puts "Initialising network..."
		HTTPoison.get("http://localhost:8880/api", ["Accept": "Application/json"],
			[recv_timeout: 10_000])
	end

	defp issue(n) do
		IO.puts "No. of requests: #{Integer.to_string(n)}\nProcessing requests..."
		urls=for _<-1..n do
			src=:rand.uniform(2264)
			dst=:rand.uniform(2264)
			Enum.join(["http://localhost:8880/api/search?source=", to_string(src),
				"&destination=", to_string(dst), "&start_time=0&end_time=172800&date="<>
				"15-3-2017"])
		end
		urls
	end

	defp process_async_requests(urls) do
		{total_async_micros, has_status_200}=:timer.tc(fn->
			Enum.reduce(1..1, false, fn(_x, acc)->
				urls|>Enum.map(fn(url)->Task.async(fn->HTTPoison.get(url, %{},
					[recv_timeout: 30_500]) end) end)
					|>Enum.map(&Task.await(&1, 31_000))|>Enum.map(fn({status, result})->
						if status==:ok do
							result.status_code
						else
							result.reason
						end
					end)
					|>Enum.reduce(false, fn(x, acc)->x==200||acc end)|>Kernel.||(acc)
			end)
		end)
		check_status_code(:async, has_status_200)
		Float.round(total_async_micros/1000, 4)
	end

	defp check_status_code(type, false) do
		IO.puts "!Warning: #{Atom.to_string(type)} request, cannot find at least "<>
			"1 HTTP status 200"
	end

	defp check_status_code(_, true) do end

end
