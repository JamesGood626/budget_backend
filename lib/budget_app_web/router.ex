defmodule BudgetAppWeb.Router do
  use BudgetAppWeb, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  scope "/", BudgetAppWeb do
    pipe_through :browser

    get "/", PageController, :index
  end

  # Other scopes may use custom stacks.
  # scope "/api", BudgetAppWeb do
  #   pipe_through :api
  # end
  scope "/api", BudgetAppWeb do
    pipe_through :api

    # /pages/:page example from here -> https://hexdocs.pm/phoenix/Phoenix.Router.html#module-helpers
    get "/pages/:page", PageController, :show
    # The key is that the helper function will be based on the controller name
    # i.e. BudgetAppWeb.Router.Helpers.auth_path(BudgetAppWeb.Endpoint, :approve_sign_up, "hello")
    # -> Helpers.auth_path
    get "/approve_sign_up", AuthController, :approve_sign_up
    get "/deny_sign_up", AuthController, :deny_sign_up

    post "/signup", AuthController, :signup
    post "/login", AuthController, :login
    post "/logout", AuthController, :logout
    resources "/account", BudgetController
    resources "/deposit", DepositController
    resources "/necessary-expense", NecessaryExpenseController
    resources "/unnecessary-expense", UnnecessaryExpenseController
  end
end
