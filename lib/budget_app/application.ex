defmodule BudgetApp.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  # pg. 229 of elixir in action covers Registry of processes
  use Application

  def start(_type, _args) do
    # List all child processes to be supervised
    children = [
      # See pg. 114 of functional web dev with elixir and otp for explanation of this stuff...
      {Registry, keys: :unique, name: Registry.BudgetServer},
      BudgetApp.BudgetSupervisor,
      BudgetApp.CredentialSupervisor,
      # Start the endpoint when the application starts
      BudgetAppWeb.Endpoint
      # Starts a worker by calling: BudgetApp.Worker.start_link(arg)
      # {BudgetApp.Worker, arg},
    ]

    :ets.new(:budget_tracker_state, [:public, :named_table])
    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: BudgetApp.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BudgetAppWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
