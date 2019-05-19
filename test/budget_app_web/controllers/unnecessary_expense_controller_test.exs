defmodule BudgetAppWeb.UnnecessaryExpenseControllerTest do
  use BudgetAppWeb.ConnCase
  alias BudgetApp.AuthService
  alias BudgetApp.{BudgetServer}
  alias BudgetApp.{CredentialServer}

  @guest_account "unnecessary_exp@gmail.com"
  @credentials %{
    "email" => "unnecessary_exp@gmail.com",
    "password" => AuthService.hash_password("password11"),
    "active" => false
  }
  @login_input %{
    "email" => "unnecessary_exp@gmail.com",
    "password" => "password11"
  }
  @unnecessary_expense_input %{
    "expense" => "Coffee",
    "amount" => 700,
    "current_month" => 5,
    "current_year" => 2019
  }
  @unnecessary_expense_post_result %{
    "category" => "UNNECESSARY_EXPENSE",
    "type" => "Coffee",
    "account_balance" => -700,
    "amount" => 700,
    "total_unnecessary_expenses" => 700
  }

  setup_all do
    BudgetServer.start_link(@guest_account)
    CredentialServer.create_credentials(@credentials)
    CredentialServer.activate_user(@credentials["email"])
  end

  test "POST /api/unnecessary-expense", %{conn: conn} do
    conn = post(conn, "/api/login", @login_input)
    conn = post(conn, "/api/unnecessary-expense", @unnecessary_expense_input)

    # Not testing that date is on the response currently
    # But it is there.
    assert @unnecessary_expense_post_result = json_response(conn, 200)
  end
end
