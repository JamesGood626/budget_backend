defmodule BudgetApp.Budget do
  use Timex
  alias Budget

  @increment "INCREMENT"
  @decrement "DECREMENT"

  defstruct budget_tracker: %{
              name: nil,
              current_month: nil,
              current_year: nil,
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

  #  current_budget will remain the same unless user updates it.
  # But  current_budget may only be edited once a month. Make commitments.
  # LAST FEATURE TO ADD:
  # Add a budget interval for the GenServer to send a budget_interval reset (handle_info)
  # Which will modify the GenServer's state and reset :budget_exceeded to false
  # If the budget was exceeded in the previous :budget_interval -> :budget_set will also
  # be toggled to false again.

  # See if I can arrange the monthly scheduled work
  # in such a way that I can just pass in current_month
  # and current_year into the budget_monthly_interval_generator
  # function from within Budget.init/1 to reduce duplication.

  def transaction_timestamp do
    if Mix.env() === :test do
      "test date"
    else
      Timex.now()
    end
  end

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

    # interval =
    #   Interval.new(from: local_datetime, until: next_month_datetime)
    #   |> Interval.duration(:days)

    # IF I can get the timezone for the user consistently with the following JS
    # code then I can handle the UTC conversion to their local time:
    # Intl.DateTimeFormat().resolvedOptions().timeZone -> "America/New_York"
    # month_ahead_date above is converted from this: 2019-04-02 03:52:55.928832Z
    # To this: #DateTime<2019-04-01 23:52:55.928832-04:00 EDT America/New_York>
    next_month_datetime = Timezone.convert(next_month_datetime, "America/New_York")
    # Eh for next month dt I get this after conversion.
    # DateTime<2019-03-31 20:00:00-04:00 EDT America/New_York>
    # Will it consistently be one day behind? -> I'll accept the eager date

    # This is the interval that needs to be used in the schedule_work function.
    interval =
      Interval.new(from: local_datetime, until: next_month_datetime)
      |> Interval.duration(:milliseconds)

    {interval, next_month, next_year}
  end

  def create_account do
    %BudgetApp.Budget{}
  end

  @doc """
  Called upon initializing budget state inside of BudgetApp.BudgetServer's init/1.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
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
          name: "random@gmail.com",
          current_month: 3,
          current_year: 2019,
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
  def initialize_budget(budget, name, current_month, current_year) do
    # LISTEN!
    # The example I found that put me on the right path.
    # I suppose there's also an Access.key/2 that allows you to populate a dynamically
    # generated key with a default value.
    # The Enum.map returns a list which contains the mapped keys in the Access.key/2
    # and then you're able to update the last item's key in the list with the
    # third arg passed into put_in
    # put_in(map_three, Enum.map([current_year, :b, :c], &Access.key(&1, %{})), 42)
    # %{2019 => %{b: %{c: 42}}}

    # This function disgusts me.
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

    updated_budget_tracker =
      put_in(
        budget.budget_tracker,
        Enum.map([:current_year], &Access.key(&1, %{})),
        current_year
      )

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker)],
        fn val ->
          {:ok, updated_budget_tracker}
        end
      )

    updated_budget_tracker =
      put_in(
        updated_budget.budget_tracker,
        Enum.map([:current_month], &Access.key(&1, %{})),
        current_month
      )

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker)],
        fn val ->
          {:ok, updated_budget_tracker}
        end
      )

    updated_years_tracked =
      put_in(
        updated_budget.budget_tracker.years_tracked,
        Enum.map([current_year, :months_tracked, current_month], &Access.key(&1, %{})),
        nested_budget_info
      )

    {:ok, updated_budget} =
      get_and_update_in(
        updated_budget,
        [Access.key!(:budget_tracker), Access.key!(:years_tracked)],
        fn val ->
          {:ok, updated_years_tracked}
        end
      )

    {:ok, updated_budget} =
      get_and_update_in(
        updated_budget,
        [Access.key!(:budget_tracker), Access.key!(:name)],
        fn val ->
          {:ok, name}
        end
      )

    updated_budget
  end

  @doc """
  Called for the monthly scheduled interval inside of BudgetApp.BudgetServer.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> BudgetApp.Budget.update_current_month_and_year(budget, 4, 2019)
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
          name: "random@gmail.com",
          current_month: 4,
          current_year: 2019,
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
                },
                4 => %{
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
            },
          }
        }
      }
  """
  def update_current_month_and_year(budget, current_month, current_year) do
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

    updated_budget_tracker =
      put_in(
        budget.budget_tracker,
        Enum.map([:current_year], &Access.key(&1, %{})),
        current_year
      )

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker)],
        fn val ->
          {:ok, updated_budget_tracker}
        end
      )

    # IO.puts("BUDGET SHOULD BE UPDATED W/ CURRENT_YEAR")
    # IO.inspect(updated_budget)

    updated_budget_tracker =
      put_in(
        updated_budget.budget_tracker,
        Enum.map([:current_month], &Access.key(&1, %{})),
        current_month
      )

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker)],
        fn val ->
          {:ok, updated_budget_tracker}
        end
      )

    updated_years_tracked =
      put_in(
        updated_budget.budget_tracker.years_tracked,
        Enum.map([current_year, :months_tracked, current_month], &Access.key(&1, %{})),
        nested_budget_info
      )

    {:ok, updated_budget} =
      get_and_update_in(
        updated_budget,
        [Access.key!(:budget_tracker), Access.key!(:years_tracked)],
        fn val ->
          {:ok, updated_years_tracked}
        end
      )

    updated_budget
  end

  @doc """
  Called upon initializing budget state for a guest account inside of BudgetApp.BudgetServer's check_guest_account/2.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> BudgetApp.Budget.set_guest_restrictions(budget)
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
          name: "random@gmail.com",
          current_month: 3,
          current_year: 2019,
          limit_requests: true,
          request_limit: 200,
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
  def set_guest_restrictions(budget) do
    updated_budget = put_in(budget.budget_tracker.limit_requests, true)
    updated_budget = put_in(updated_budget.budget_tracker.request_limit, 200)

    updated_budget
  end

  @doc """
  Called upon initializing budget state inside of BudgetApp.BudgetServer whenever a handle_call
  or handle_cast is executed.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> budget = BudgetApp.Budget.set_guest_restrictions(budget)
      iex> BudgetApp.Budget.increment_serviced_requests(budget)
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
          name: "random@gmail.com",
          current_month: 3,
          current_year: 2019,
          limit_requests: true,
          request_limit: 200,
          serviced_requests: 1,
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
  def increment_serviced_requests(budget) do
    {:ok, updated_budget_tracker} =
      get_and_update_in(
        budget,
        [Access.key!(:budget_tracker), Access.key!(:serviced_requests)],
        fn val ->
          {:ok, val + 1}
        end
      )

    updated_budget_tracker
  end

  @doc """
  Called inside of BudgetApp.BudgetServer's authorize_request/2 when determining whether
  a guest has exceeded their daily alotted request limit.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> budget = BudgetApp.Budget.set_guest_restrictions(budget)
      iex> BudgetApp.Budget.check_serviced_requests(budget)
      {:ok, "Allow request."}
  """
  def check_serviced_requests(
        %{budget_tracker: %{request_limit: request_limit, serviced_requests: serviced_requests}} =
          budget
      ) do
    case serviced_requests <= request_limit do
      true ->
        {:ok, "Allow request."}

      false ->
        {:err, "Deny request."}
    end
  end

  @doc """
  Accepts budget state as an argument and resets serviced_requests to 0.
  schedule_daily_work that is called every 24 hours schedules
  handle_info(:reset_serviced_requests, state) in BudgetApp.Budget to be called periodically.


  Usage:
    The reset_serviced_requests/1 function is called inside of
    the BudgetServer GenServer module every 24 hour interval.

    The handle_info/2 which pattern matches on :reset_serviced_requests
    is where this function is called.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.set_guest_restrictions(budget)
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
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
          name: "random@gmail.com",
          current_month: 3,
          current_year: 2019,
          limit_requests: true,
          request_limit: 200,
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
  def reset_serviced_requests(budget) do
    put_in(budget.budget_tracker.serviced_requests, 0)
  end

  # Deposits below before misplan
  # deposits: [%{"income_source" => "check", "deposit_amount" => 50000}],

  @doc """
    The deposit/3 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 12, 2020)
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 1, 2021)
      iex> BudgetApp.Budget.deposit(budget, %{"income_source" => "check", "deposit_amount" => 50000}, {1, 2021})
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
          name: "random@gmail.com",
          current_month: 1,
          current_year: 2021,
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
            },
            2020 => %{
              months_tracked: %{
                12 => %{
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
            },
            2021 => %{
              months_tracked: %{
                1 => %{
                  budget: 0,
                  budget_exceeded: false,
                  deposits: [%{
                    category: "DEPOSIT",
                    type: "check",
                    account_balance: 50000,
                    amount: 50000,
                    date: BudgetApp.Budget.transaction_timestamp()
                  }],
                  necessary_expenses: [],
                  total_deposited: 50000,
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
  def deposit(
        budget,
        %{"income_source" => income_source, "deposit_amount" => deposit_amount},
        {current_month, current_year}
      ) do
    monthly_list_item_payload = %{
      category: "DEPOSIT",
      type: income_source,
      amount: deposit_amount,
      date: transaction_timestamp()
    }

    update_account_balance(@increment, budget, deposit_amount)
    |> update_monthly_total(
      :total_deposited,
      deposit_amount,
      current_year,
      current_month
    )
    |> update_monthly_list(:deposits, monthly_list_item_payload, current_year, current_month)
  end

  # Really just keeping this around for future reference
  # year_key_list =
  #   updated_budget.budget_tracker.years_tracked
  #   |> Enum.map(fn {key, val} -> key end)
  #   |> Enum.reverse()
  # Gets the last month in the data structure to update total_deposited.
  # current_year = List.first(year_key_list)

  # month_key_list =
  #   updated_budget.budget_tracker.years_tracked[current_year].months_tracked
  #   |> Enum.map(fn {key, val} -> key end)
  #   |> Enum.reverse()
  # current_month = List.first(month_key_list)

  # Old return format (client relies on updated version)
  # necessary_expenses: [%{"expense" => "phone", "expense_amount" => 10000}],

  @doc """
    The necessary_expense/3 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 12, 2020)
      iex> BudgetApp.Budget.necessary_expense(budget, %{"expense" => "phone", "expense_amount" => 10000}, {12, 2020})
      %BudgetApp.Budget{
        budget_tracker: %{
          budget: %{
            current_budget: nil,
            budget_set: false,
            account_balance: -10000,
            budget_exceeded: false,
          },
          timers: %{
            daily_timer: nil,
            monthly_timer: nil
          },
          name: "random@gmail.com",
          current_month: 12,
          current_year: 2020,
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
            },
            2020 => %{
              months_tracked: %{
                12 => %{
                  budget: 0,
                  budget_exceeded: false,
                  deposits: [],
                 necessary_expenses: [%{
                    category: "NECESSARY_EXPENSE",
                    type: "phone",
                    account_balance: -10000,
                    amount: 10000,
                    date: BudgetApp.Budget.transaction_timestamp()
                  }],
                  total_deposited: 0,
                  total_necessary_expenses: 10000,
                  total_unnecessary_expenses: 0,
                  unnecessary_expenses: []
                }
              }
            }
          }
        }
      }
  """
  def necessary_expense(
        budget,
        %{"expense" => expense, "expense_amount" => expense_amount} = transaction_slip,
        {current_month, current_year}
      ) do
    monthly_list_item_payload = %{
      category: "NECESSARY_EXPENSE",
      type: expense,
      amount: expense_amount,
      date: transaction_timestamp()
    }

    update_account_balance(@decrement, budget, expense_amount)
    |> update_monthly_total(
      :total_necessary_expenses,
      expense_amount,
      current_year,
      current_month
    )
    |> update_monthly_list(
      :necessary_expenses,
      monthly_list_item_payload,
      current_year,
      current_month
    )
  end

  # Again old format due to client needing different format
  # unnecessary_expenses: [%{"expense" => "coffee", "expense_amount" => 500}]

  @doc """
    The necessary_expense/3 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 12, 2020)
      iex> BudgetApp.Budget.unnecessary_expense(budget, %{"expense" => "coffee", "expense_amount" => 500}, {12, 2020})
      %BudgetApp.Budget{
        budget_tracker: %{
          budget: %{
            current_budget: nil,
            budget_set: false,
            account_balance: -500,
            budget_exceeded: false,
          },
          timers: %{
            daily_timer: nil,
            monthly_timer: nil
          },
          name: "random@gmail.com",
          current_month: 12,
          current_year: 2020,
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
            },
            2020 => %{
              months_tracked: %{
                12 => %{
                  budget: 0,
                  budget_exceeded: false,
                  deposits: [],
                  necessary_expenses: [],
                  total_deposited: 0,
                  total_necessary_expenses: 0,
                  total_unnecessary_expenses: 500,
                  unnecessary_expenses: [%{
                    category: "UNNECESSARY_EXPENSE",
                    type: "coffee",
                    account_balance: -500,
                    amount: 500,
                    date: BudgetApp.Budget.transaction_timestamp()
                  }],
                }
              }
            }
          }
        }
      }
  """
  def unnecessary_expense(
        budget,
        %{"expense" => expense, "expense_amount" => expense_amount} = transaction_slip,
        {current_month, current_year}
      ) do
    monthly_list_item_payload = %{
      category: "UNNECESSARY_EXPENSE",
      type: expense,
      amount: expense_amount,
      date: transaction_timestamp()
    }

    update_account_balance(@decrement, budget, expense_amount)
    |> update_monthly_total(
      :total_unnecessary_expenses,
      expense_amount,
      current_year,
      current_month
    )
    |> update_monthly_list(
      :unnecessary_expenses,
      monthly_list_item_payload,
      current_year,
      current_month
    )
  end

  defp update_account_balance(type, budget, amount) do
    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        reference_nested(:account_balance),
        fn val ->
          account_balance_crement(val, type, amount)
        end
      )

    updated_budget
  end

  def account_balance_crement(val, type, amount) do
    case type do
      "INCREMENT" ->
        {:ok, val + amount}

      "DECREMENT" ->
        {:ok, val - amount}
    end
  end

  defp update_monthly_total(budget, key, amount, current_year, current_month) do
    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        reference_nested(current_year, current_month, key),
        fn val ->
          {:ok, val + amount}
        end
      )

    updated_budget
  end

  defp update_monthly_list(budget, key, transaction_slip, current_year, current_month) do
    transaction_slip =
      Map.put_new(
        transaction_slip,
        :account_balance,
        # the first budget is really the top level struct...
        budget.budget_tracker.budget.account_balance
      )

    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        reference_nested(current_year, current_month, key),
        fn val ->
          {:ok, [transaction_slip | val]}
        end
      )

    updated_budget
  end

  @doc """
    The necessary_expense/3 function is called inside of
    the BudgetServer GenServer module.

    The handle_call/2 which pattern matches on :deposit
    is where this function is called, and passes the budget
    held in GenServer state, as well as a user entered amount to
    update the account_balance state with.

  ## Examples

      iex> budget = BudgetApp.Budget.create_account()
      iex> budget = BudgetApp.Budget.initialize_budget(budget, "random@gmail.com", 3, 2019)
      iex> BudgetApp.Budget.set_budget(budget, 60000, 3, 2019)
      %BudgetApp.Budget{
        budget_tracker: %{
          budget: %{
            current_budget: 60000,
            budget_set: true,
            account_balance: 0,
            budget_exceeded: false,
          },
          timers: %{
            daily_timer: nil,
            monthly_timer: nil
          },
          name: "random@gmail.com",
          current_month: 3,
          current_year: 2019,
          limit_requests: false,
          request_limit: 0,
          serviced_requests: 0,
          years_tracked: %{
            2019 => %{
              months_tracked: %{
                3 => %{
                  budget: 60000,
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
  def set_budget(budget, budget_amount, current_month, current_year) do
    # Is there a better way -_-
    {:ok, updated_budget} =
      get_and_update_in(
        budget,
        reference_nested(:current_budget),
        fn val ->
          {:ok, budget_amount}
        end
      )

    {:ok, updated_budget} =
      get_and_update_in(
        updated_budget,
        reference_nested(:budget_set),
        fn val ->
          {:ok, true}
        end
      )

    {:ok, updated_budget} =
      get_and_update_in(
        updated_budget,
        reference_nested(current_year, current_month, :budget),
        fn val ->
          {:ok, budget_amount}
        end
      )

    updated_budget
  end

  def reference_nested(:account_balance) do
    [Access.key!(:budget_tracker), Access.key!(:budget), Access.key!(:account_balance)]
  end

  def reference_nested(:current_budget) do
    [
      Access.key!(:budget_tracker),
      Access.key!(:budget),
      Access.key!(:current_budget)
    ]
  end

  def reference_nested(:budget_set) do
    [
      Access.key!(:budget_tracker),
      Access.key!(:budget),
      Access.key!(:budget_set)
    ]
  end

  def reference_nested(year, month, :budget) do
    [
      Access.key!(:budget_tracker),
      Access.key!(:years_tracked),
      Access.key!(year),
      Access.key!(:months_tracked),
      Access.key!(month),
      Access.key!(:budget)
    ]
  end

  def reference_nested(year, month, key) do
    [
      Access.key!(:budget_tracker),
      Access.key!(:years_tracked),
      Access.key!(year),
      Access.key!(:months_tracked),
      Access.key!(month),
      Access.key!(key)
    ]
  end

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
