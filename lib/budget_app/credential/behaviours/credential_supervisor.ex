defmodule BudgetApp.CredentialSupervisor do
  use Supervisor
  alias BudgetApp.CredentialServer

  def start_link(_options) do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      CredentialServer
    ]

    # Once the supervisor starts, it will traverse the list of children and it will
    # invoke the child_spec/1 function on each module.
    # The child_spec/1 function returns the child specification which describes how to start
    # the process, if the process is a worker or a supervisor, if the process is temporary,
    # transient, or permanent, and so on.
    # The child_spec/1 function is automatically defined when we *use Agent*, *use GenServer*,
    # *use Supervisor*, etc.
    Supervisor.init(children, strategy: :one_for_one)
  end
end
