defmodule TS.Station.Supervisor do
	@moduledoc """
	Module for implementing station process supervision functionality. Supervisor process supervises other
	processes, which we refer to as child processes. In the event of station process crashing,
	TS.Station.Supervisor is responsible for restarting it based on the exit reasons and strategies
	mentioned.

	Uses Supervisor.
	"""
	use Supervisor

	@name TS.Station.Supervisor

	@doc """
	Starts a station supervisor process with the given module and arg.

	To start the supervisor, the `init/1` callback will be invoked in the given module, with arg as its
	argument. The `init/1` callback must return a supervisor specification which can be created with the
	help of the functions in the Supervisor.Spec module.

	### Parameters
	For Station, required parameters passed to Supervisor function are `Supervisor.start_link(__MODULE__, 
	:ok, name: @name)`, specifying:

	module_name

	args

	options:
	- :name - used for name registration
	- :timeout - if present, the server is allowed to spend the given amount of milliseconds initializing
	or it will be terminated and the start function will return {:error, :timeout}
	- :debug - if present, the corresponding function in the :sys module is invoked
	- :spawn_opt - if present, its value is passed as options to the underlying process
	
	### Strategies
	Supervisors support different supervision strategies (through the :strategy option):
	- :one_for_one - if a child process terminates, only that process is restarted.
	- :one_for_all - if a child process terminates, all other child processes are terminated and then 
	all child processes (including the terminated one) are restarted.
	- :rest_for_one - if a child process terminates, the rest of the child processes, ie, the child
	processes after the terminated one in start order, are terminated. Then the terminated child process
	and the rest of the child processes are restarted.
	- :simple_one_for_one - similar to :one_for_one but suits better when dynamically attaching children.
	This strategy requires the supervisor specification to contain only one child.

	### Exit reasons
	There are three options:
	- :normal - in such cases, the exit won't be logged, there is no restart in transient mode, and linked 
	processes do not exit.
	- :shutdown or {:shutdown, term} - in such cases, the exit won't be logged, there is no restart in
	transient mode, and linked processes exit with the same reason unless they're trapping exits.
	- any other term - in such cases, the exit will be logged, there are restarts in transient mode, and
	linked processes exit with the same reason unless they're trapping exits.

	### Return values
	If the `init/1` callback returns :ignore, this function returns :ignore as well and the supervisor
	terminates with reason :normal. If it fails or returns an incorrect value, this function returns 
	{:error, term} where term is a term with information about the error, and the supervisor terminates
	with reason term.
	"""
	def start_link do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	@doc """
	Dynamically adds a child specification to supervisor and starts that child.

	child_spec should be a valid child specification (unless the supervisor is a :simple_one_for_one
	supervisor). The child process will be started as defined in the child specification.

	In the case of :simple_one_for_one, the child specification defined in the supervisor is used and
	instead of a child_spec, an arbitrary list of terms is expected. The child process will then be
	started by appending the given list to the existing function arguments in the child specification.

	### Parameters
	For Station, required parameters passed to Supervisor function are `Supervisor.start_child(@name, [])`,
	specifying:

	supervisor_name

	child_specs_or_args

	### Return values
	If a child specification with the specified id already exists, child_spec is discarded and this 
	function returns an error with :already_started or :already_present if the corresponding child process
	is running or not, respectively.

	If the child process start function returns {:ok, child} or {:ok, child, info}, then child 
	specification and PID are added to the supervisor and this function returns the same value.   
	If the child process start function returns :ignore, the child specification is added to the
	supervisor, the PID is set to :undefined and this function returns {:ok, :undefined}.

	If the child process start function returns an error tuple or an erroneous value, or if it fails,
	the child specification is discarded and this function returns {:error, error} where error is a
	term containing information about the error and child specification.
	"""
	def start_station do
		Supervisor.start_child(@name, [])
	end

	def init(:ok) do
		children=[
			worker(Station, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end

end
