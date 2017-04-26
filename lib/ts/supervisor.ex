defmodule TS.Supervisor do
	@moduledoc """
	Mmodule for implementing supervision functionality. Supervisor process supervises other processes, which we refer to as child processes.
	"""
	use Supervisor

	@doc """
	Starts a supervisor process with the given module and arg.   
	To start the supervisor, the `init/1` callback will be invoked in the given module, with arg as its argument. The `init/1` callback must return a supervisor specification which can be created with the help of the functions in the Supervisor.Spec module.
   
	### Parameters
	module   
	args   
	name
	- The :name option can also be given in order to register a supervisor name.

	### Strategies
	Supervisors support different supervision strategies (through the :strategy option):
	- :one_for_one - if a child process terminates, only that process is restarted.
	- :one_for_all - if a child process terminates, all other child processes are terminated and then all child processes (including the terminated one) are restarted.
	- :rest_for_one - if a child process terminates, the rest of the child processes, ie, the child processes after the terminated one in start order, are terminated. Then the terminated child process and the rest of the child processes are restarted.
	- :simple_one_for_one - similar to :one_for_one but suits better when dynamically attaching children. This strategy requires the supervisor specification to contain only one child.

	### Exit reasons
	There are three options:
	- :normal - in such cases, the exit won't be logged, there is no restart in transient mode, and linked processes do not exit.
	- :shutdown or {:shutdown, term} - in such cases, the exit won't be logged, there is no restart in transient mode, and linked processes exit with the same reason unless they're trapping exits.
	- any other term - in such cases, the exit will be logged, there are restarts in transient mode, and linked processes exit with the same reason unless they're trapping exits.

	### Return values
	If the `init/1` callback returns :ignore, this function returns :ignore as well and the supervisor terminates with reason :normal. If it fails or returns an incorrect value, this function returns {:error, term} where term is a term with information about the error, and the supervisor terminates with reason term.
	"""
	def start_link do
		Supervisor.start_link(__MODULE__, :ok)
	end

	def init(:ok) do
		children=[
			worker(StationConstructor, [StationConstructor]),
			supervisor(TS.API.Supervisor, []),
			supervisor(TS.Station.Supervisor, [])
		]
		supervise(children, strategy: :rest_for_one)
	end

end
