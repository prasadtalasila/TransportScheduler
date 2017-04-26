defmodule Mix.Tasks.Benchmark do
	@moduledoc """
	Module to run asynchronous benchmark to test multiple, concurrent queries
	"""
	use Mix.Task
	alias Mix.Tasks.AsyncBm, as: AsyncBm

	def run(_args) do
		Mix.Task.run "app.start", []
		#f=File.open!("data/test.csv", [:append])
		#IO.write(f, CSVLixir.write_row(["No.", "Source", "Destination",
		#	"Start time", "End time", "QPT (ms)"]))
		#File.close(f)
		AsyncBm.setup
		for x<-1..1 do
			{async_result, src, dst, start_time, cutoff_time}=AsyncBm.run()
			if async_result !==:wrong do
				IO.puts "#{async_result} ms"
				f=File.open!("data/test.csv", [:append])
				IO.write(f, CSVLixir.write_row([x, src, dst, start_time,
					cutoff_time, async_result]))
				File.close(f)
			end
		end
	end

	#defp parse_args(args) do
		#{options, _, _}=OptionParser.parse(args, [
			#switches: [loop: :integer],
			#aliases: [l: :loop]
		#])
		#parse_options(options)
	#end

	#defp parse_options([loop: loop]), do: loop

	#defp parse_options(_), do: 10 # loop defs to 10

end
