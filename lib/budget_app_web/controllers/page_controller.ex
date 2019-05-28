defmodule BudgetAppWeb.PageController do
  use BudgetAppWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
