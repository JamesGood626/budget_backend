defmodule BudgetSupervisorTest do
  use ExUnit.Case, async: true
  alias BudgetApp.{BudgetSupervisor, BudgetServer, Budget}

  @primary_account "James"
  @fail_account "FailAccount"
  # @initial_account_data %Budget{
  #   budget_tracker: %{
  #     budget: %{
  #       account_balance: 0,
  #       budget_exceeded: false,
  #       budget_set: false,
  #       current_budget: nil
  #     },
  #     timers: %{
  #       daily_timer: nil,
  #       monthly_timer: nil
  #     },
  #     limit_requests: false,
  #     request_limit: 0,
  #     serviced_requests: 0,
  #     years_tracked: %{
  #       2019 => %{
  #         months_tracked: %{
  #           3 => %{
  #             budget: 0,
  #             budget_exceeded: false,
  #             deposits: [],
  #             necessary_expenses: [],
  #             total_deposited: 0,
  #             total_necessary_expenses: 0,
  #             total_unnecessary_expenses: 0,
  #             unnecessary_expenses: []
  #           }
  #         }
  #       }
  #     }
  #   }
  # }

  setup_all do
    BudgetSupervisor.start_link(%{})
    BudgetSupervisor.start_budget(@primary_account)
    # The map returned in the tuple below can be pattern matched
    # on in the second argument of the test macro.
    {:ok, %{}}
  end

  # Keeping this around for later reference for how to test processes that should
  # exit.
  # test "Unauthorized process name should error." do
  #   Process.flag(:trap_exit, true)
  #   {:ok, pid} = BudgetSupervisor.start_budget(@fail_account)
  #   # sleep is necessary to allow the process to shutdown in time for the assert.
  #   :timer.sleep(100)
  #   assert Process.alive?(pid) === false
  # end

  # test "Can deposit." do
  #   # Do Deposit
  #   %{budget_tracker: budget_tracker} = BudgetServer.get_account(@primary_account)
  # end

  # Tests I could write but decided not to.
  # "Primary account requests aren't limited"
  # "Guest account requests are limited"
end
