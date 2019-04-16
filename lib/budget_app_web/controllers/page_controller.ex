defmodule BudgetAppWeb.PageController do
  use BudgetAppWeb, :controller

  def index(conn, _params) do
    IO.puts("WOOT!!!!!")
    render(conn, "index.html")
  end

  def show(conn, params) do
    IO.puts("HIT THE PAGE CONTROLLEr'S SHOW CONTROLLER")
    IO.puts("Here's the params")
    IO.inspect(params)
  end
end
