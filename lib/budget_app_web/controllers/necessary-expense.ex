defmodule BudgetAppWeb.NecessaryExpenseController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  @doc """
    A POST to create a new deposit.
  """
  def create(conn, %{"expense" => expense, "amount" => amount} = params) do
    # A call to BudgetServer client function
    json(conn, %{message: "You deposit it #{expense}"})
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

# In this case /api/necessary-expense is our resource

# review_path  GET     /admin/reviews           HelloWeb.Admin.ReviewController :index
# review_path  GET     /admin/reviews/:id/edit  HelloWeb.Admin.ReviewController :edit
# review_path  GET     /admin/reviews/new       HelloWeb.Admin.ReviewController :new
# review_path  GET     /admin/reviews/:id       HelloWeb.Admin.ReviewController :show
# review_path  POST    /admin/reviews           HelloWeb.Admin.ReviewController :create
# review_path  PATCH   /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
#              PUT     /admin/reviews/:id       HelloWeb.Admin.ReviewController :update
# review_path  DELETE  /admin/reviews/:id       HelloWeb.Admin.ReviewController :delete
