defmodule BudgetApp.BudgetSupervisor do
  use DynamicSupervisor
  alias BudgetApp.BudgetServer

  # TODO!!!
  # Just realized the UI flow that I've currently set up won't work for the
  # account creation & retrieval. I'll need to issue two requests from the UI
  # in order to facilitate that process.
  # Well in order to prevent tomfoolery on my server I could do:
  #   - Don't even expose an account creation endpoint... Let me just handle that from the CLI
  #   - Look further into the DDoS stuff and see what viable options there are regarding prevention.
  # When not using a DynamicSupervisor... This start_link/0 is called.
  # Calling this module's start_budget/0 yields:
  # {:error, {:invalid_mfa, {BudgetApp.BudgetServer, :start_link, "James"}}}
  # def start_link() do
  #   IO.puts("WILL I SEE THIS? Not anymore...")
  # end

  def start_link(_options) do
    IO.puts("DynamicSupervisor start_link/1 called!")
    DynamicSupervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end

  def start_budget(name) do
    DynamicSupervisor.start_child(__MODULE__, {BudgetServer, name})
  end
end

# The use Supervisor implementation I had before use DynamicSupervisor
# defmodule BudgetApp.BudgetSupervisor do
#   use Supervisor
#   alias BudgetApp.BudgetServer

#   def start_link() do
#     IO.puts("WILL I SEE THIS?")
#   end

#   def start_link(_options) do
#     IO.puts("SUPERVISOR start_link/1 called!")
#     Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
#   end

#   def init(:ok) do
#     children = [
#       BudgetServer
#     ]

#     # Once the supervisor starts, it will traverse the list of children and it will
#     # invoke the child_spec/1 function on each module.
#     # The child_spec/1 function returns the child specification which describes how to start
#     # the process, if the process is a worker or a supervisor, if the process is temporary,
#     # transient, or permanent, and so on.
#     # The child_spec/1 function is automatically defined when we *use Agent*, *use GenServer*,
#     # *use Supervisor*, etc.
#     Supervisor.init(children, strategy: :one_for_one)
#   end

#   def start_budget(name),
#     do: Supervisor.start_child(__MODULE__, [name])
# end
