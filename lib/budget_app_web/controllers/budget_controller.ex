defmodule BudgetAppWeb.BudgetController do
  use BudgetAppWeb, :controller
  alias BudgetApp

  import BudgetApp.Auth
  plug :authorize_user

  @doc """
    A GET to retrieve an existing account
  """
  def index(conn, _params) do
    # Contains email & remember_token
    # Move this line into a function plug to place above protected routes for AuthZ
    # session_data = get_session(conn, :session_token)
    # IO.puts("THE CONN:")
    # IO.inspect(conn)
    %{current_user: current_user} = conn.assigns
    IO.puts("THE conn.assigns.current_user")
    IO.inspect(current_user)
    # cookie = conn.fetch_cookies()
    # IO.puts("THE FETCHED COOKIE")
    # IO.inspect(cookie)
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
