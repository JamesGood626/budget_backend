defmodule BudgetAppWeb.NecessaryExpenseControllerTest do
  use BudgetAppWeb.ConnCase
  alias BudgetApp.AuthService
  alias BudgetApp.{BudgetServer}
  alias BudgetApp.{CredentialServer}

  {:ok, %{month: month}} = DateTime.now("Etc/UTC")

  @guest_account "necessary_exp@gmail.com"
  @credentials %{
    "email" => "necessary_exp@gmail.com",
    "password" => AuthService.hash_password("password11"),
    "active" => false
  }
  @login_input %{
    "email" => "necessary_exp@gmail.com",
    "password" => "password11"
  }
  @necessary_expense_input %{
    "expense" => "Rent",
    "amount" => 90000,
    "current_month" => month,
    "current_year" => 2019
  }
  @necessary_expense_post_result %{
    "category" => "NECESSARY_EXPENSE",
    "type" => "Rent",
    "account_balance" => -90000,
    "amount" => 90000,
    "total_necessary_expenses" => 90000
  }

  setup_all do
    BudgetServer.start_link(@guest_account)
    CredentialServer.create_credentials(@credentials)
    CredentialServer.activate_user(@credentials["email"])
  end

  test "POST /api/necessary-expense", %{conn: conn} do
    conn = post(conn, "/api/login", @login_input)
    conn = post(conn, "/api/necessary-expense", @necessary_expense_input)

    assert @necessary_expense_post_result = json_response(conn, 200)
  end
end
