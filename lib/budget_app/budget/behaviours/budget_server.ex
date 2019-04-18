defmodule BudgetApp.BudgetServer do
  # The child process is restarted only if it terminates abnormally,
  # i.e. with an exit reason other than :normal, :shutdown, or {:shutdown, term}
  use GenServer, restart: :transient
  alias BudgetApp.Budget

  @daily_interval 60 * 60 * 24
  # New considerations... Just handle account creation by doing an email request to my email.
  # Additionally, introduce authentication so that a session cookie with the name of the account
  # will be available in the controllers, so that it may be passed in to the entry function for the
  # business logic.
  # Mar 19th TODO:
  #  - Finish testing GenServer behavior
  #  - Create more robust ETS set
  #  - Test supervision of GenServer processes/fail states/reinitialized successfully.
  # To minimize race condition chances -> Make it so that
  # a user may only make a deposit/expense if the budget has been set.
  # That way fresh state won't be able to be modified and succeed, then we can
  # send back a message to the user that the update wasn't applied.
  # BUT... is all this really worth it?

  # LAST LEFT OFF testing deposit.
  # STILL NEED TO ADD LOGIC IN THE BudgetApp.Budget.deposit/2 function
  # to add a map to the nested deposits list inside of years_tracked.2019.months_tracked.1.deposits
  # ACCOMPLISHING THE ABOVE WILL REQUIRE SOME REWORKING OF THE DATE FUNCTIONS TO RETURN THE CURRENT
  # YEAR AND MONTH SO THAT THOSE MAY BE ADDED INTO the years_tracked map, AS IT IS CURRENTLY EMPTY
  # UPON INITIALIZATION AS IT STANDS RIGHT NOW.
  #  1st and Foremost -> -> -> set up ETS!!!!!
  #  1. Then I can move onto handling set_budget call/handle_call
  #     and associated docttests for the functions inside BudgetApp.Budget for set_budget
  #  2. Handle call/handle_call for get_account
  #     and associated docttests for the functions inside BudgetApp.Budget for get_account
  #  3. Handle call/handle_call for create_unnecessary_expense
  #     and associated docttests for the functions inside BudgetApp.Budget for create_unnecessary_expense
  #  4. Create and handle call/handle_call for create_necessary_expense
  #     and associated docttests for the functions inside BudgetApp.Budget for create_necessary_expense
  #     after creating it.
  #  5. Create a reset_budget function in BudgetApp.Budget module
  #     to accomodate resetting the budget_set flag to false on the
  #     monthly interval.
  @doc """
    Name will serve as the sole reference to the account in GenServer state.

    Shape of GenServer state
    Why Did I Choose this State Shape?
    I figured it would facilitate filtering by month/year
    on the client side.
    %{
      limit_requests: false (if me)/true (if guest)
      request_limit: 50,
      serviced_requests: 0,
      budget: %{
        account_balance: 0,
        current_budget: nil,
        budget_exceeded: false,
        budget_set: false
      },
      intervals: %{
        daily_interval: nil, # takes milliseconds
        monthly_interval: nil # takes milliseconds
      },
      years_tracked: %{
        2019: %{
          months_tracked: %{
            1: %{
              Also include the budget amount that was set here so that it can
              be viewed as well in the UI when tracking previous months
              budget: 27000,
              # Add to these totals serverside
              total_deposited: 470000,
              total_necessary_expenses: *total it up*,
              total_unnecessary_expenses: *total it up*,
              budget_exceeded: false
              deposits: [
                %{
                  deposit_type: 'Check',
                  amount: 500000,
                  date: *createDate*
                }
              ],
              necessary_expenses: [
                %{
                  expense_type: 'Rent',
                  # That's New York for ya (also, prob do the cents representation for monies)
                  # so 3600 * 100 = 360000 i.e. 3600.00 <- figure how to format with decimal in elixir
                  amount: 360000
                }
              ],
              unnecessary_expenses: [
                %{
                  expense_type: 'Coffee' # Let's be honest... This is necessary.
                  amount: 5000,
                  date: *createDate*
                }
              ],
            }
          }
        },
        2020: %{
          months_tracked: %{
            1: %{
              budget: 27000,
              total_deposited: 470000,
              deposits: [
                %{
                  deposit_type:
                }
              ],
              total_necessary_expenses: *total it up*,
              necessary_expenses: [
                %{
                  expense_type:
                }
              ],
              total_unnecessary_expenses: *total it up*,
              unnecessary_expenses: [
                %{
                  expense_type:
                }
              ]
            }
          }
        }
      }
    }
  """
  # This was the bane of my existence for a two days or so.
  # When attempting to set up a Supervisor that could dynamically
  # spawn GenServer processes as children.... This function was being
  # called after calling Supervisor.start_link
  # BUT THE THING IS... It seems as though elixir went through an update
  # that incorporated the behaviour I needed into DynamicSupervisor
  # and now everything works just fine.
  # def start_link() do
  #   IO.puts("DAFUQ?")
  # end

  def start_link(name) do
    IO.puts("BUDGET SERVER START_LINK RUNNING")
    IO.inspect(name)
    GenServer.start_link(__MODULE__, name, name: via_tuple(name))
  end

  @doc """
    The third element in the tuple is a tuple of the shape:
    {registry_name, process_key}
  """
  def via_tuple(name), do: {:via, Registry, {Registry.BudgetServer, name}}

  # FOR MAKING ETS WORK I'LL ALWAYS NEED ACCESS TO THE NAME OF THE ACCOUNT
  # WHICH WAS JUST UPDATED.
  # It would be ideal to handle this in one location... To do something like that
  # I think the only option would be to create a helper function inside the
  # BudgetApp.Budget module which all functions in that module will call just before
  # returning their output.
  # Nonetheless, it will require passing the name as an argument to all of the GenServer.call/2s
  # in order to have that accessible for updating the state in ETS.
  def get_account(name) do
    GenServer.call(via_tuple(name), {:get_account, name})
  end

  def deposit(name, transaction_slip, current_date) do
    GenServer.call(via_tuple(name), {:deposit, name, transaction_slip, current_date})
  end

  def necessary_expense(name, transaction_slip, current_date) do
    GenServer.call(via_tuple(name), {:necessary_expense, name, transaction_slip, current_date})
  end

  def unnecessary_expense(name, transaction_slip, current_date) do
    GenServer.call(via_tuple(name), {:unnecessary_expense, name, transaction_slip, current_date})
  end

  def set_budget(name, budget_limit) do
    GenServer.call(via_tuple(name), {:set_budget, budget_limit})
  end

  # Add date as an arg
  def create_unnecessary_expense(name, amount) do
    GenServer.call(via_tuple(name), {:create_unnecessary_expense, amount})
  end

  # Server Callbacks
  def init(name) do
    # Possibly pass in user's local timezone(for the budget_interval_generator) in the future.
    # Really need to schedule_work twice:
    #   - Once for the monthly state update interval -> schedule_monthly_work
    #   - Another for freshing the Guest account's serviced_requests every 24 hours. schedule_daily_work

    # This approach of sending a message (asynchonrously) to the GenServer process in an attempt
    # to prevent any long running logic in init/1 from blocking start_link/1 from
    # finishing may result in race conditions. Because there may be other messages
    # that hit the mailbox before :set_state -> Reference: https://elixirschool.com/blog/til-genserver-handle-continue/
    # send(self(), {:set_state, name, state})
    {:ok, %{}, {:continue, {:set_state, name}}}
  end

  @doc """
    Message returned as the third element in the tuple returned from inside init/1
    triggers this to be immediately executed following init/1 and before any other messages
    may be sent to the process. Therefore eliminating race conditions.
    This is done in order to determine if ets already has the state associated with
    a given name.
    This is part of process crash state recovery.
  """
  def handle_continue({:set_state, name}, _state) do
    IO.puts("INSIDE HANDLE CONTINUE")
    # i.e. if current_month = 3 and current_year = 19
    #      then next_month = 4 and year = 19
    {_datetime, current_month, current_year} = Budget.get_current_date()
    IO.puts("cureent_month")
    IO.inspect(current_month)
    IO.puts("cureent_year")
    IO.inspect(current_year)
    state = fresh_state(name, current_month, current_year)
    state = schedule_monthly_work(state)

    state =
      case :ets.lookup(:budget_tracker_state, name) do
        [] ->
          state

        [{_key, state}] ->
          state
      end

    update_ets_state(name, state)
    {:noreply, state}
  end

  defp fresh_state(name, current_month, current_year) do
    state =
      Budget.create_account()
      |> Budget.initialize_budget(name, current_month, current_year)
      |> check_guest_account(name)
  end

  # Test kater to see if you can pattern match existing variables with
  # the incoming function params. i.e. if there were env vars for the
  # random account names, could I have multiple function clauses to check
  # each one.
  defp check_guest_account(state, name) do
    # If you're not James or Guest... You shall not pass!
    IO.puts("check_guest_account running!!!!!!")

    # Old impl.
    # case name do
    #   "Guest" ->
    #     {state} = schedule_daily_work(state)
    #     Budget.set_guest_restrictions(state)

    #   "James" ->
    #     state

    #   _ ->
    #     IO.puts("SHUTTING IT DOWN!")
    #     Process.exit(self(), :shutdown)
    # end

    case name do
      "james.good@codeimmersives.com" ->
        state

      _ ->
        new_state =
          schedule_daily_work(state)
          |> Budget.set_guest_restrictions()

        update_ets_state(state.budget_tracker.name, new_state)
        IO.puts("STATE THAT GUEST IS INITIALIZED WITH")
        IO.inspect(new_state)
        new_state
    end
  end

  # The init function from function-web-development-with-elixir book
  # They allow init to initialize the state,
  # by creating the state in the second argument to GenServer.start_link/3
  # def init(name) do
  #   player1 = %{name: name, board: Board.new(), guesses: Guesses.new()}
  #   player2 = %{name: nil, board: Board.new(), guesses: Guesses.new()}
  #   {:ok, %{player1: player1, player2: player2, rules: %Rules{}}}
  # end

  @doc """
    Pulling off current_year and year because current_year will be used for
    the initial initialization, and there's a possibility that year could be
    equal to the current_year, or that it may be the next_year.

    i.e. The current_month is December, the current_year is 2018, and year is 2019.
  """
  defp schedule_monthly_work(
         %{budget_tracker: %{timers: %{monthly_timer: monthly_timer}}} = state
       ) do
    # Need to pull off current_month and current_year from this as well from setting up initial state.
    cancel_timer(monthly_timer)
    {monthly_interval, next_month, next_year} = Budget.budget_monthly_interval_generator()

    IO.puts("Scheduling....")
    # you need to break this scheduling of the timer out into a helper function to facilitate
    # testing, and then pass in the monthly interval as dependency injection.
    # All this in order to determine if the data structure continues to update accordingly.
    # Process.send_after/3 -> Third arg is milliseconds
    monthly_timer =
      Process.send_after(
        self(),
        {:reset_budget_interval, next_month, next_year},
        monthly_interval
      )

    new_state = put_in(state.budget_tracker.timers.monthly_timer, monthly_timer)
    update_ets_state(state.budget_tracker.name, new_state)
    new_state
  end

  # Need to manually test that the reset is truly occuring.
  # Also, what would be the most ideal way to test these schedule_work
  # intervals to ensure that they're truly doing what they're meant to
  # before deploying into production?
  defp schedule_daily_work(%{budget_tracker: %{timers: %{daily_timer: daily_timer}}} = state) do
    IO.puts("Scheduling daily work!!!!!!")
    cancel_timer(daily_timer)

    # Set the daily_interval to twenty four hours
    daily_timer = Process.send_after(self(), :reset_serviced_requests, @daily_interval)
    new_state = put_in(state.budget_tracker.timers.daily_timer, daily_timer)
    update_ets_state(state.budget_tracker.name, new_state)
    new_state
  end

  defp cancel_timer(timer) do
    if timer do
      IO.puts("CANCELING TIMER")
      IO.inspect(timer)
      Process.cancel_timer(timer)
    end
  end

  # THIS IS WHERE YOU LEFT OFF.... DO WORK.
  # Before doing work, it has occured to me that there are a few things
  # which I should probably add to state in order to achieve the desired
  # resulting system:
  #     - Should I create a key or something for each thing that's created
  #     - so that the created resource may be undone?
  #     - However, as far as preventing DDoS goes, this approach will not be sufficient. <- Research
  def handle_info({:reset_budget_interval, next_month, next_year}, state) do
    # Use next_month and next_year to add updated state for the new
    # Create new year and month in years_tracked/months_tracked
    # Reset budget_set to false
    # Reset budget_exceeded to false
    # Reset transactions_total

    IO.puts("THE HANDLE INTERVAL TRIGGERED")
    IO.inspect(next_month)
    IO.inspect(next_year)
    # Reschdule once more
    state = schedule_monthly_work(state)

    new_state = Budget.update_current_month_and_year(state, next_month, next_year)
    {:noreply, new_state}
  end

  def handle_info(:reset_serviced_requests, state) do
    IO.puts("THE :reset_serviced_requests handle_info TRIGGERED")
    # IO.inspect(state)
    Budget.reset_serviced_requests(state)
    new_state = schedule_daily_work(state)
    {:noreply, new_state}
  end

  # Could instead pattern match on the name.. but again, not
  # sure if I'll be able to pattern match on the value of
  # env_variables based on a config variable set in this project.
  # Doubt it will be possible though.
  def handle_call({:get_account, name}, _from, state) do
    new_state = increment_guest_serviced_requests(state, name)
    update_ets_state(name, new_state)
    {:reply, new_state, new_state}
  end

  # :deposit, :necessary_expense, and :unnecessary_expense could all use a refactor...
  # much better would be to just create a helper function in the budget_serrvice that
  # handles all of the stuff that's going on inside of the handle_call/3's
  def handle_call({:deposit, name, transaction_slip, current_date}, _from, state) do
    # Possibly create a helper function for successful and failure cases
    # So that this case block may be used in a HOF where you pass those in as args
    # and whatever the return result from that is what gets returned from all
    # handle calls.
    case authorize_request(state, name) do
      false ->
        {:reply, "Requests serviced exceeded.", state}

      state ->
        case increment_guest_serviced_requests(state, name) do
          false ->
            {:reply, "invalid_request", state}

          state ->
            # This could be pipelined.
            new_state = Budget.deposit(state, transaction_slip, current_date)
            update_ets_state(name, new_state)
            {:reply, new_state, new_state}
        end
    end
  end

  def handle_call({:necessary_expense, name, transaction_slip, current_date}, _from, state) do
    # Possibly create a helper function for successful and failure cases
    # So that this case block may be used in a HOF where you pass those in as args
    # and whatever the return result from that is what gets returned from all
    # handle calls.
    case authorize_request(state, name) do
      false ->
        {:reply, "Requests serviced exceeded.", state}

      state ->
        case increment_guest_serviced_requests(state, name) do
          false ->
            {:reply, "invalid_request", state}

          state ->
            # This could be pipelined.
            new_state = Budget.necessary_expense(state, transaction_slip, current_date)
            update_ets_state(name, new_state)
            {:reply, new_state, new_state}
        end
    end
  end

  def handle_call({:unnecessary_expense, name, transaction_slip, current_date}, _from, state) do
    # Possibly create a helper function for successful and failure cases
    # So that this case block may be used in a HOF where you pass those in as args
    # and whatever the return result from that is what gets returned from all
    # handle calls.
    case authorize_request(state, name) do
      false ->
        {:reply, "Requests serviced exceeded.", state}

      state ->
        case increment_guest_serviced_requests(state, name) do
          false ->
            {:reply, "invalid_request", state}

          state ->
            # This could be pipelined.
            new_state = Budget.unnecessary_expense(state, transaction_slip, current_date)
            update_ets_state(name, new_state)
            {:reply, new_state, new_state}
        end
    end
  end

  # Sooo, the problem with this is that I'll need to call
  # authorize request inside the handle_call(s) in order to have access to state
  # But this could mean that a deluge of requests could still come in, defeating the
  # purpose of why I even set out to do this. Well.. not entirely, state won't be built
  # up nonstop, but DDoS is still something I need to determine how to prevent.
  defp authorize_request(state, "james.good@codeimmersives.com"), do: state

  defp authorize_request(state, _guest_name) do
    case Budget.check_serviced_requests(state) do
      true ->
        state

      _ ->
        false
    end
  end

  defp increment_guest_serviced_requests(state, "james.good@codeimmersives.com"), do: state

  defp increment_guest_serviced_requests(state, _guest_name),
    do: Budget.increment_serviced_requests(state)

  # TODO: wrap this function to be called within another function that pattern matches on the response
  # and then returns the new_state to facilitate pipelining.
  defp update_ets_state(name, new_state),
    do: :ets.insert(:budget_tracker_state, {name, new_state})

  # def handle_call({:set_budget, budget_limit}, _from, state) do
  #   new_state = Budget.set_budget(state, budget_limit)
  #   {:reply, new_state, new_state}
  # end

  # def handle_call({:create_unnecessary_expense, amount}, _from, state) do
  #   new_state = Budget.create_unnecessary_expense(state, amount)
  #   {:reply, new_state, new_state}
  # end
end

# :ets.lookup(:budget_tracker_state, "random@gmail.com")

# alias BudgetApp.BudgetServer
# {:ok, pid} = BudgetServer.start_link("random@gmail.com")
# BudgetServer.deposit("random@gmail.com", %{"income_source" => "check", "deposit_amount" => 400000}, {4, 2019})
# BudgetServer.unnecessary_expense("random@gmail.com", %{"expense" => "coffee", "expense_amount" => 500}, {4, 2019})
# BudgetServer.necessary_expense("random@gmail.com", %{"expense" => "phone", "expense_amount" => 10000}, {4, 2019})

# BudgetApp.BudgetServer.create_unnecessary_expense(:James, 200)
# BudgetApp.BudgetServer.set_budget(:James, 400)
# BudgetApp.BudgetServer.create_unnecessary_expense(:James, 200) -> budget_exceeded: false
# BudgetApp.BudgetServer.create_unnecessary_expense(:James, 300) -> budget_exceeded: true
