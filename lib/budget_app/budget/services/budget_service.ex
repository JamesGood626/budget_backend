defmodule BudgetApp.Budget do
  use Timex
  alias Budget

  defstruct budget_tracker: %{
              limit_requests: false,
              request_limit: 0,
              serviced_requests: 0,
              timers: %{
                daily_timer: nil,
                monthly_timer: nil
              },
              budget: %{
                account_balance: 0,
                current_budget: nil,
                budget_exceeded: false,
                budget_set: false
              },
              years_tracked: %{}
            }

  # budget_limit will remain the same unless user updates it.
  # But budget_limit may only be edited once a month. Make commitments.
  # LAST FEATURE TO ADD:
  # Add a budget interval for the GenServer to send a budget_interval reset (handle_info)
  # Which will modify the GenServer's state and reset :budget_exceeded to false
  # If the budget was exceeded in the previous :budget_interval -> :budget_set will also
  # be toggled to false again.

  # See if I can arrange the monthly scheduled work
  # in such a way that I can just pass in current_month
  # and current_year into the budget_monthly_interval_generator
  # function from within Budget.init/1 to reduce duplication.

  @spec get_current_date() :: {DateTime.t(), pos_integer(), integer()}
  def get_current_date do
    datetime = Timex.now()
    {datetime, datetime.month, datetime.year}
  end

  def budget_monthly_interval_generator do
    {datetime, current_month, current_year} = get_current_date()
    next_month = get_next_month(current_month)
    next_year = get_next_year(next_month, current_year)

    {:ok, next_month_datetime} = Date.new(next_year, next_month, 1)

    # "America/New_York" or whatever could be passed in as a param to start_budget when
    # posting to create a new account @ /api/account
    local_datetime = Timezone.convert(datetime, "America/New_York")

    interval =
      Interval.new(from: local_datetime, until: next_month_datetime)
      |> Interval.duration(:days)

    # IF I can get the timezone for the user consistently with the following JS
    # code then I can handle the UTC conversion to their local time:
    # Intl.DateTimeFormat().resolvedOptions().timeZone -> "America/New_York"
    # month_ahead_date above is converted from this: 2019-04-02 03:52:55.928832Z
    # To this: #DateTime<2019-04-01 23:52:55.928832-04:00 EDT America/New_York>
    next_month_datetime = Timezone.convert(next_month_datetime, "America/New_York")
    # Eh for next month dt I get this after conversion.
    # DateTime<2019-03-31 20:00:00-04:00 EDT America/New_York>
    # Will it consistently be one day behind? -> I'll accept the eager date

    # This is the interval that I need to be used in the schedule_work function.
    interval =
      Interval.new(from: local_datetime, until: next_month_datetime)
      |> Interval.duration(:milliseconds)

    {interval, next_month, next_year}
  end

  def create_account do
    %BudgetApp.Budget{}
  end

  # %BudgetApp.Budget{
  #   budget_tracker: %{
  #     budget: %{
  #       budget_limit: 0,
  #       budget_set: false,
  #       account_balance: 0,
  #       unnecessary_expense_total: 0
  #     },
  #     limit_requests: false,
  #     request_limit: 200,
  #     serviced_requests: 0,
  #     years_tracked: %{}
  #   }
  # }

  @doc """
  Called upon initializing budget state inside of BudgetApp.BudgetServer's init/1.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> BudgetApp.Budget.initialize_budget(budget, 3, 2019)
      %BudgetApp.Budget{
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
  """
  def initialize_budget(budget, current_month, current_year) do
    # The example I found that put me on the right path.
    # I suppose there's also an Access.key/2 that allows you to populate a dynamically
    # generated key with a default value.
    # The Enum.map returns a list which contains the mapped keys in the Access.key/2
    # and then you're able to update the last item's key in the list with the
    # third arg passed into put_in
    # put_in(map_three, Enum.map([current_year, :b, :c], &Access.key(&1, %{})), 42)
    # %{2019 => %{b: %{c: 42}}}

    # This function could use some refactoring... But later.
    nested_budget_info = %{
      budget: 0,
      total_deposited: 0,
      total_necessary_expenses: 0,
      total_unnecessary_expenses: 0,
      budget_exceeded: false,
      deposits: [],
      necessary_expenses: [],
      unnecessary_expenses: []
    }

    updated_years_tracked =
      put_in(
        budget.budget_tracker.years_tracked,
        Enum.map([current_year, :months_tracked, current_month], &Access.key(&1, %{})),
        nested_budget_info
      )

    Map.put(budget.budget_tracker, :years_tracked, updated_years_tracked)

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker), Access.key!(:years_tracked)],
        fn val ->
          {:ok, updated_years_tracked}
        end
      )

    updated_budget
  end

  # updated_years_tracked =
  #   Map.put(budget.budget_tracker.years_tracked, current_year, %{
  #     months_tracked: %{}
  #   })

  # updated_months_tracked =
  #   Map.put(budget.budget_tracker.years_tracked[current_year].months_tracked, current_month, %{
  #     budget: 0,
  #     total_deposited: 0,
  #     total_necessary_expenses: 0,
  #     total_unnecessary_expenses: 0,
  #     budget_exceeded: false,
  #     deposits: [],
  #     necessary_expenses: [],
  #     unnecessary_expenses: []
  #   })

  def set_guest_restrictions(budget) do
    updated_budget = put_in(budget.budget_tracker.limit_requests, true)
    updated_budget = put_in(updated_budget.budget_tracker.request_limit, 200)

    IO.puts("BUDGET UPDATED WITH TIMER")
    IO.inspect(updated_budget)
    updated_budget
  end

  def increment_serviced_requests(budget) do
    # HOW DO I HANDLE POTENTIAL ERRORS FOR THIS get_and_update_in?
    {:ok, updated_budget_tracker} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker), Access.key!(:serviced_requests)],
        fn val ->
          {:ok, val + 1}
        end
      )

    IO.inspect(updated_budget_tracker)
    updated_budget_tracker
  end

  def check_serviced_requests(
        %{budget_tracker: %{request_limit: request_limit, serviced_requests: serviced_requests}} =
          budget
      ) do
    serviced_requests < request_limit
  end

  @doc """
  Accepts budget state as an argument and resets
  serviced_requests to 0.

  Usage:
    The reset_serviced_requests/1 function is called inside of
    the BudgetServer GenServer module every 24 hour interval.

    The handle_info/2 which pattern matches on :reset_serviced_requests
    is where this function is called.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.set_guest_restrictions(budget)
      iex> budget = BudgetApp.Budget.increment_serviced_requests(budget)
      iex> BudgetApp.Budget.reset_serviced_requests(budget)
      %BudgetApp.Budget{
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
          limit_requests: true,
          request_limit: 200,
          serviced_requests: 0,
          years_tracked: %{}
        }
      }
  """
  def reset_serviced_requests(budget) do
    put_in(budget.budget_tracker.serviced_requests, 0)
  end

  # Testing the two deposit/2 function clauses with doctest
  # Will only work for one at a time... Both tests are passing right now
  # BUT I'll need to look further into this.
  # Perhaps move out the get_in_and_update logic to another function
  # test that with a doctest, and then manually unit test the two
  # separate function clauses

  @doc """
  Accepts budget state as an argument and resets
  serviced_requests to 0.
  †
  Usage:
    The deposit/2 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

    This function should only execute when Budget.budget_tracker.limit_requests
    is set to true.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.set_guest_restrictions(budget)
      iex> BudgetApp.Budget.deposit(budget, 20000)
      %BudgetApp.Budget{
        budget_tracker: %{
          budget: %{
            account_balance: 20000,
            current_budget: nil,
            budget_set: false,
            budget_exceeded: false
          },
          timerss: %{
            daily_timers: nil,
            monthly_timers: nil
          },
          limit_requests: true,
          request_limit: 200,
          serviced_requests: 1,
          years_tracked: %{}
        }
      }
  """
  def deposit(%BudgetApp.Budget{budget_tracker: %{limit_requests: true}} = budget, amount) do
    IO.puts("THE LIMIT REQUESTS DEPOSIT BEING TRIGGERED")

    {:ok, updated_account_balance} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker), Access.key!(:budget), Access.key!(:account_balance)],
        fn val ->
          {:ok, val + amount}
        end
      )

    BudgetApp.Budget.increment_serviced_requests(updated_account_balance)
  end

  @doc """
  Accepts budget state as an argument and resets
  serviced_requests to 0.

  Usage:
    The deposit/2 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> BudgetApp.Budget.deposit(budget, 50000)
      %BudgetApp.Budget{
        budget_tracker: %{
          budget: %{
            current_budget: nil,
            budget_set: false,
            account_balance: 50000,
            budget_exceeded: false,
          },
          timers: %{
            daily_timer: nil,
            monthly_timer: nil
          },
          limit_requests: false,
          request_limit: 0,
          serviced_requests: 0,
          years_tracked: %{}
        }
      }
  """
  def deposit(budget, amount) do
    # HOW DO I HANDLE POTENTIAL ERRORS FOR THIS get_and_update_in?
    {:ok, updated_account_balance} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker), Access.key!(:budget), Access.key!(:account_balance)],
        fn val ->
          {:ok, val + amount}
        end
      )

    # Update the nested deposits array
    # years_tracked.current_year(num).months_tracked.current_month(num).deposits
    # be sure to add to the total_deposited as well.
    updated_account_balance
  end

  # Change this to set the nested budget -> Can't handle this until
  # I refactor to create the initial set up
  #   def set_budget(budget, budget_limit) do
  #     %BudgetApp.Budget{budget | budget_limit: budget_limit, budget_set: true}
  #   end

  # Probably won't need the second function clause and can just change the first arg
  # to be budget for this one.
  # Add the expense -> expense_type, amount, and date to the nested list in
  # years_tracked.current_year(num).months_tracked.current_month(num).unnecessary_expenses
  #   def create_unnecessary_expense(%{budget_set: false} = budget, amount) do
  #     new_total = budget.total - amount
  #     new_unnecessary_expense_total = budget.unnecessary_expense_total + amount

  #     %BudgetApp.Budget{
  #       budget
  #       | total: new_total,
  #         unnecessary_expense_total: new_unnecessary_expense_total
  #     }

  # Update the nested unnecessary_expense array
  # years_tracked.current_year(num).months_tracked.current_month(num).deposits
  # be sure to add to the total_deposited as well.
  #   end

  ###############
  ## DEPRECATE ##
  ###############
  #   def create_unnecessary_expense(%{budget_set: true} = budget, amount) do
  #     new_total = budget.total - amount
  #     new_unnecessary_expense_total = budget.unnecessary_expense_total + amount
  #     budget_exceeded = new_unnecessary_expense_total > budget.budget_limit

  #     %BudgetApp.Budget{
  #       budget
  #       | total: new_total,
  #         unnecessary_expense_total: new_unnecessary_expense_total,
  #         budget_exceeded: budget_exceeded
  #     }
  #   end

  # This kind of logic would be perfect to use property based testing on...
  defp get_next_month(current_month) do
    if current_month < 12 do
      current_month + 1
    else
      1
    end
  end

  defp get_next_year(next_month, current_year) do
    if next_month === 1 do
      current_year + 1
    else
      current_year
    end
  end
end
