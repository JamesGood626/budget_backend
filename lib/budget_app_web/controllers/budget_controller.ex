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
    # current_user is the user's email
    %{current_user: current_user} = conn.assigns
    %{budget_tracker: budget_tracker} = BudgetServer.get_account(current_user)
    %{budget: budget, years_tracked: years_tracked} = budget_tracker

    IO.puts("THIS IS WHAT'S GETTING ENCODED")
    IO.inspect(%{budget: budget, years_tracked: years_tracked})

    json_resp =
      %{budget: budget, years_tracked: years_tracked}
      |> Poison.encode!()

    json(conn, json_resp)
  end

  @doc """
    A POST to create a new account with total initialized to 0.
  """
  def create(conn, %{"name" => name} = params) do
    name = String.to_atom(name)

    case BudgetServer.start_link(name) do
      {:ok, pid} ->
        json(conn, %{message: "You created it"})

      _ ->
        json(conn, %{message: "You done fucked up"})
    end
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
