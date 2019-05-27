defmodule BudgetAppWeb.DepositController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  import BudgetApp.Auth
  plug :authorize_user

  @invalid_session_message "INVALID_SESSION"

  # TODO:
  # 2. Implement the set_budget function in budget_service.ex
  #    and corresponding Budget GenServer handler
  # 3. After two is done. Implement the react reducer to add
  #    that budget into the nested month data so that a total
  #    may be calculated for the Aggregated Budget:
  @doc """
    A POST to create a new deposit.
  """
  def create(
        conn,
        %{
          "income_source" => income_source,
          "deposit_amount" => deposit_amount,
          "current_month" => current_month,
          "current_year" => current_year
        } = params
      ) do
    case conn.assigns do
      %{current_user: nil} ->
        json(conn, %{message: @invalid_session_message})

      # current_user is the user's email.
      %{current_user: current_user} ->
        # TODO:
        # Last left off w/ updating the return format to facilitate a payload of this structure:
        # %{
        #   category: "DEPOSIT",
        #   type: "check",
        #   account_balance: 1000,
        #   amount: 2000,
        #   date: transaction_timestamp()
        # }
        # Need to ensure that I destructure that off of the call to BudgetServer.deposit below
        # As well as update the expense controllers to return a similar structure as well.
        # This will actually require returning the entire Budget struct + the structure above
        # from the budget service functions -> to save on nested retrieval.
        %{budget_tracker: %{budget: budget, years_tracked: years_tracked}} =
          BudgetServer.deposit(
            current_user,
            %{"income_source" => income_source, "deposit_amount" => deposit_amount},
            {current_month, current_year}
          )

        current_month_data = years_tracked[current_year].months_tracked[current_month]

        # This is the format that the client expects now.... This is what not planning ahead
        # Gets ya.
        payload = %{
          category: "DEPOSIT",
          type: income_source,
          account_balance: budget.account_balance,
          total_deposited: current_month_data.total_deposited,
          amount: deposit_amount,
          date: Timex.now()
        }

        json(conn, payload)
    end
  end
end

# In this case /api/deposit is our resource

# review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
# review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
# review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
# review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
# review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
# review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
#              PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
# review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
