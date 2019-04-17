defmodule BudgetAppWeb.DepositController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  @doc """
    A POST to create a new deposit.
  """
  def create(
        conn,
        %{"income_source" => income_source, "deposit_amount" => deposit_amount} = params
      ) do
    # current_user is the user's email
    %{current_user: current_user} = conn.assigns
    %{budget_tracker: budget_tracker} = BudgetServer.deposit(params)

    # json_resp =
    #   %{budget: budget, years_tracked: years_tracked}
    #   |> Poison.encode!()

    # json(conn, json_resp)

    # Need to refactor Budget to have current_month & current_year stored in
    # budget_tracker to facilitate posting current_month & current_year to this
    # controller (also benefits client side so they know how to update data structure there)
    # so that this controller can only return the new changes -> to avoid having to send the
    # entire data structure every time.
    json(conn, %{message: "You deposit it #{income_source}"})
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
