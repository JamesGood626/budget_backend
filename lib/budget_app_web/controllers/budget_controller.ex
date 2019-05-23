defmodule BudgetAppWeb.BudgetController do
  use BudgetAppWeb, :controller
  alias BudgetApp
  alias BudgetApp.BudgetServer

  import BudgetApp.Auth
  plug :authorize_user

  @doc """
    A GET to retrieve an existing account
  """
  def index(conn, _params) do
    # TODO: REFACTOR THIS FROM OUT OF THE CONTROLLER!!!!
    # current_user is the user's email
    %{current_user: current_user} = conn.assigns
    IO.puts("THE CURRENT USER")
    IO.inspect(current_user)
    %{budget_tracker: budget_tracker} = BudgetServer.get_account(current_user)

    %{
      budget: budget,
      years_tracked: years_tracked,
      current_month: current_month,
      current_year: current_year
    } = budget_tracker

    payload = %{
      budget: budget,
      years_tracked: years_tracked,
      current_month: current_month,
      current_year: current_year
    }

    json(conn, payload)
  end

  @doc """
    A POST to create a new monthly budget
  """
  def create(
        conn,
        %{
          "budget_amount" => budget_amount,
          "current_month" => current_month,
          "current_year" => current_year
        } = params
      ) do
    %{current_user: current_user} = conn.assigns

    %{budget_tracker: %{budget: budget, years_tracked: years_tracked}} =
      BudgetServer.set_budget(current_user, budget_amount, current_month, current_year)

    payload = %{
      message: "Successfully set your budget for the month.",
      current_month: current_month,
      current_year: current_year,
      updated_month_data: years_tracked[current_year][:months_tracked][current_month],
      budget: budget
    }

    json(conn, payload)
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
