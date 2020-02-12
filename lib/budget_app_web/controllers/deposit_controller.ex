defmodule BudgetAppWeb.DepositController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  import BudgetApp.Auth
  plug :authorize_user

  @invalid_session_message "INVALID_SESSION"

  # Would refactor this logic out into a service file if there
  # were more than one controller...

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
    IO.inspect("the conn.assigns")
    IO.inspect(conn.assigns)

    case conn.assigns do
      %{current_user: nil} ->
        json(conn, %{message: @invalid_session_message})

      # current_user is the user's email.
      %{current_user: current_user} ->
        IO.puts("current_user")
        IO.inspect(current_user)

        payload =
          BudgetServer.deposit(
            current_user,
            %{"income_source" => income_source, "deposit_amount" => deposit_amount},
            {current_month, current_year}
          )
          |> IO.inspect()
          |> format_result(params)
          |> IO.inspect()

        json(conn, payload)
    end
  end

  # %{budget_tracker: %{budget: budget, years_tracked: years_tracked}} =
  #   BudgetServer.deposit(
  #     current_user,
  #     %{"income_source" => income_source, "deposit_amount" => deposit_amount},
  #     {current_month, current_year}
  #   )

  # Should've formatted this to return as:
  # %{type: "DEPOSIT_SUCCESS", message: "Your deposit went through!", data: payload }
  def format_result(
        %{budget_tracker: %{budget: budget, years_tracked: years_tracked}},
        %{
          "income_source" => income_source,
          "deposit_amount" => deposit_amount,
          "current_month" => current_month,
          "current_year" => current_year
        }
      ) do
    current_month_data = years_tracked[current_year].months_tracked[current_month]

    %{
      category: "DEPOSIT",
      type: income_source,
      account_balance: budget.account_balance,
      total_deposited: current_month_data.total_deposited,
      amount: deposit_amount,
      date: Timex.now()
    }
  end

  def format_result(data = %{type: "REQUEST_LIMIT_EXCEEDED", message: message}, _params), do: data
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
