defmodule TS.API.Supervisor do
	@moduledoc """
	Mmodule for implementing API process supervision functionality. Supervisor process supervises other processes, which we refer to as child processes.
	"""
	use Supervisor
	@name TS.API.Supervisor

	@doc """
	Starts an API supervisor process with the given module and arg.   
	To start the supervisor, the `init/1' callback will be invoked in the given module, with arg as its argument. The `init/1' callback must return a supervisor specification which can be created with the help of the functions in the Supervisor.Spec module.
   
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
	If the `init/1' callback returns :ignore, this function returns :ignore as well and the supervisor terminates with reason :normal. If it fails or returns an incorrect value, this function returns {:error, term} where term is a term with information about the error, and the supervisor terminates with reason term.
	"""
	def start_link do
		Supervisor.start_link(__MODULE__, :ok, name: @name)
	end

	@doc """
	Dynamically adds a child specification to supervisor and starts that child.   
	child_spec should be a valid child specification (unless the supervisor is a :simple_one_for_one supervisor). The child process will be started as defined in the child specification.
	In the case of :simple_one_for_one, the child specification defined in the supervisor is used and instead of a child_spec, an arbitrary list of terms is expected. The child process will then be started by appending the given list to the existing function arguments in the child specification.

	### Parameters
	supervisor   
	child_specs_or_args

	### Return values
	If a child specification with the specified id already exists, child_spec is discarded and this function returns an error with :already_started or :already_present if the corresponding child process is running or not, respectively.   
	If the child process start function returns {:ok, child} or {:ok, child, info}, then child specification and PID are added to the supervisor and this function returns the same value.   
	If the child process start function returns :ignore, the child specification is added to the supervisor, the PID is set to :undefined and this function returns {:ok, :undefined}.   
	If the child process start function returns an error tuple or an erroneous value, or if it fails, the child specification is discarded and this function returns {:error, error} where error is a term containing information about the error and child specification.
	"""
	def start_api do
		Supervisor.start_child(@name, [])
	end

	def init(:ok) do
		children=[
			worker(API, [], restart: :temporary)
		]
		supervise(children, strategy: :simple_one_for_one)
	end
end
