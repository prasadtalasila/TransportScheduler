defmodule Mix.Tasks.AsyncBm do
	use Mix.Task

	def run(mix_args) do
		n=mix_args
		setup
		issue(n)|>process_async_requests
	end

	def setup do
		:ok=:hackney_pool.start_pool(:first_pool, [timeout: 35000,
			max_connections: 1000])
		HTTPoison.start
	end

	defp issue(n) do
		IO.puts "no. of requests: #{Integer.to_string(n)}\nprocessing requests.."
		HTTPoison.get("http://localhost:8880/api", ["Accept": "Application/json"],
			[recv_timeout: 10_000])
		urls=for _ <- 1..n do
			src=:rand.uniform(2264)
			dst=:rand.uniform(2264)
			Enum.join(["http://localhost:8880/api/search?source=", to_string(src),
				"&destination=", to_string(dst), "&start_time=0&date=15-3-2017"])
		end
		urls
	end

	defp process_async_requests(urls) do
		{total_async_micros, has_status_200}=:timer.tc(fn->
			Enum.reduce(1..1, false, fn(_x, acc)->
				urls|>Enum.map(fn(url)->Task.async(fn->HTTPoison.get(url) end) end)
					|>Enum.map(&Task.await(&1, 30000))|>Enum.map(fn({status, result})->
						if (status==:ok) do
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
