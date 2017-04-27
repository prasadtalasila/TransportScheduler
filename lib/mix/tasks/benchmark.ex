defmodule Mix.Tasks.Benchmark do
	@moduledoc """
	Helper module to run asynchronous benchmark to test multiple, concurrent queries.
	"""
	use Mix.Task
	alias Mix.Tasks.AsyncBm, as: AsyncBm

	@doc """
	Runs the Benchmark task with the given args.

	
	### Parameters
	arg   
	
	### Return values
	If the task was not yet invoked, it runs the task and returns the result.
	If there is an alias with the same name, the alias will be invoked instead of the original task.
	If the task or alias were already invoked, it does not run them again and simply aborts with :noop.  
	"""
	def run(_args) do
		Mix.Task.run "app.start", []
		f=File.open!("data/test.csv", [:write])
		IO.write(f, CSVLixir.write_row(["no.of_reqs", "async_qpt"]))
		File.close(f)
		AsyncBm.setup
		for x<-[1, 2, 3] do
			async_result=AsyncBm.run(x)
			IO.puts "#{async_result} ms"
			f=File.open!("data/test.csv", [:append])
			IO.write(f, CSVLixir.write_row([x, async_result]))
			File.close(f)
		end
	end

	#defp parse_args(args) do
		# {options, _, _}=OptionParser.parse(args, [
			#switches: [loop: :integer],
			#aliases: [l: :loop]
		#])
		#parse_options(options)
	#end

	#defp parse_options([loop: loop]), do: loop

	#defp parse_options(_), do: 10 # loop defs to 10

end
