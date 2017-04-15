defmodule Mix.Tasks.Benchmark do
	use Mix.Task

	def run(args) do
		Mix.Task.run "app.start", []
		f=File.open!("data/test.csv", [:write])
		IO.write(f, CSVLixir.write_row(["no.of_reqs", "async_qpt"]))
		File.close(f)
		for x<-1..parse_args(args) do
			async_result=Mix.Tasks.AsyncBm.run(x)
			#IO.inspect async_result
			f=File.open!("data/test.csv", [:append])
			IO.write(f, CSVLixir.write_row([x, async_result]))
			File.close(f)
		end
	end

	defp parse_args(args) do
		{options, _, _}=OptionParser.parse(args, [
			switches: [loop: :integer],
			aliases: [l: :loop]
		])
		parse_options(options)
	end

	defp parse_options([loop: loop]), do: loop

	defp parse_options(_), do: 10 # loop defs to 10

end
