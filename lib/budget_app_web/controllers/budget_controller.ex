defmodule BudgetAppWeb.BudgetController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetServer

  @doc """
    A GET to retrieve an existing account
  """
  def index(conn, _params) do
    # IO.puts("GET INDEX HIT")
    # [{_, name}] = Enum.filter(conn.req_headers, fn {key, _} -> key === "name" end)
    # name = String.to_atom(name)
    # account = BudgetServer.get_account(name)

    # IO.puts("GOT DA ACCOUNT")
    # IO.inspect(account)
    # # This Does indeed return
    # json(conn, Map.from_struct(account))
    json(conn, %{aws_success: "it's indeed alive"})
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
