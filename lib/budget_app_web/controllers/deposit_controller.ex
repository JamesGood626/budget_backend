defmodule BudgetAppWeb.DepositController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  import BudgetApp.Auth
  plug :authorize_user

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
    # current_user is the user's email
    %{current_user: current_user} = conn.assigns

    %{budget_tracker: %{budget: budget, years_tracked: years_tracked}} =
      BudgetServer.deposit(current_user, params, {current_month, current_year})

    current_month_data = years_tracked[current_year].months_tracked[current_month]

    payload = %{
      account_balance: budget.account_balance,
      total_deposited: current_month_data.total_deposited,
      deposits: current_month_data.deposits
    }

    json_resp =
      payload
      |> Poison.encode!()

    json(conn, json_resp)
  end

  @doc """
    A DELETE to delete an existing deposit.
  """
  def delete(conn, _params) do
    %{"id" => id} = conn.params
    # A call to BudgetServer client function
    json(conn, %{message: "You deposit delete it: #{id}"})
  end
end

# In this case /api/account is our resource

# review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
# review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
# review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
# review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
# review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
# review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
#              PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
# review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
