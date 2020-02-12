defmodule BudgetServerTest do
  use ExUnit.Case, async: true
  alias BudgetApp.{BudgetServer, Budget}

  @primary_account "jamesgood626@gmail.com"
  @guest_account "guest@gmail.com"
  @initial_account_data %Budget{
    budget_tracker: %{
      budget: %{
        account_balance: 0,
        budget_exceeded: false,
        budget_set: false,
        current_budget: nil
      },
      timers: %{
        daily_timer: nil,
        monthly_timer: nil
      },
      limit_requests: false,
      request_limit: 0,
      serviced_requests: 0,
      years_tracked: %{
        2019 => %{
          months_tracked: %{
            3 => %{
              budget: 0,
              budget_exceeded: false,
              deposits: [],
              necessary_expenses: [],
              total_deposited: 0,
              total_necessary_expenses: 0,
              total_unnecessary_expenses: 0,
              unnecessary_expenses: []
            }
          }
        }
      }
    }
  }

  setup_all do
    BudgetServer.start_link(@primary_account)
    BudgetServer.start_link(@guest_account)
    primary_state = BudgetServer.get_account(@primary_account)
    guest_state = BudgetServer.get_account(@guest_account)
    # The map returned in the tuple below can be pattern matched
    # on in the second argument of the test macro.
    {:ok, %{primary_state: primary_state, guest_state: guest_state}}
  end

  test "budget_tracker.timers.monthly_timer and daily_timer are references to a timer.", %{
    primary_state: primary_state,
    guest_state: guest_state
  } do
    # primary_account doesn't have a daily_timer, as it's used to reset the guest_account's request
    # restrictions.
    %{budget_tracker: budget_tracker} = primary_state
    assert is_reference(budget_tracker.timers.monthly_timer) === true
    assert is_reference(budget_tracker.timers.daily_timer) === false

    %{budget_tracker: budget_tracker} = guest_state
    assert is_reference(budget_tracker.timers.monthly_timer) === true
    assert is_reference(budget_tracker.timers.daily_timer) === true
  end

  test "guest_account state is initialized with restrictions", %{guest_state: guest_state} do
    %{
      limit_requests: limit_requests,
      request_limit: request_limit,
      serviced_requests: serviced_requests
    } = guest_state.budget_tracker

    assert limit_requests === true
    assert request_limit === 200
    assert serviced_requests === 1
  end

  test "guest_account's state serviced_requests is incremented after fulfilling a request.", %{
    guest_state: guest_state
  } do
    %{
      limit_requests: limit_requests,
      request_limit: request_limit,
      serviced_requests: serviced_requests
    } = guest_state.budget_tracker

    assert limit_requests === true
    assert request_limit === 200
    assert serviced_requests === 1
  end

  # Tests I could write but decided not to.
  # "Primary account requests aren't limited"
  # "Guest account requests are limited"
end
