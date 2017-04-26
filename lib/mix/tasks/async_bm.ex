defmodule Mix.Tasks.AsyncBm do
	@moduledoc """
	Helper module to run asynchronous benchmark
	"""

	def run do
		issue()|>process_request
	end

	def setup do
		:ok=:hackney_pool.start_pool(:first_pool, [timeout: 35_000,
			max_connections: 1000])
		HTTPoison.start
		IO.puts "Initialising network..."
		HTTPoison.get("http://localhost:8880/api", ["Accept": "application/json"],
			[recv_timeout: 10_000])
	end

	defp issue do
		#IO.puts "No. of requests: #{Integer.to_string(1)}\nProcessing requests..."
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

	defp process_request({uri, src, dst, start_time, cutoff_time}) do
		if uri !==:wrong do
			{time, _}=:timer.tc(fn->uri|>HTTPoison.get(
				["Content-Type": "application/json"], [recv_timeout: 30_500]) end)
			{Float.round(time/1000, 4), src, dst, start_time, cutoff_time}
		else
			{:wrong, src, dst, start_time, cutoff_time}
		end
	end

	#defp process_async_requests({urls, src, dst, start_time, cutoff_time}) do
		#{total_async_micros, has_status_200}=:timer.tc(fn->
			#Enum.reduce(1..1, false, fn(_x, acc)->
				#urls|>Enum.map(fn(url)->Task.async(fn->HTTPoison.get(url, %{},
					#[recv_timeout: 30_500]) end) end)
					#|>Enum.map(&Task.await(&1, 31_000))|>Enum.map(fn({status, result})->
						#if status==:ok do
							#result.status_code
						#else
							#result.reason
						#end
					#end)
					#|>Enum.reduce(false, fn(x, acc)->x==200||acc end)|>Kernel.||(acc)
			#end)
		#end)
		#check_status_code(:async, has_status_200)
		#{Float.round(total_async_micros/1000, 4), src, dst, start_time, cutoff_time}
	#end

	#defp check_status_code(type, false) do
		#IO.puts "!Warning: #{Atom.to_string(type)} request, cannot find at least "<>
			#{}"1 HTTP status 200"
	#end

	#defp check_status_code(_, true) do end

end
