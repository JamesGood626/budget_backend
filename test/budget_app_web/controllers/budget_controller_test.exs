defmodule BudgetAppWeb.BudgetControllerTest do
  use BudgetAppWeb.ConnCase
  alias BudgetApp.AuthService
  alias BudgetApp.{BudgetServer}
  alias BudgetApp.{CredentialServer}

  @guest_account "budget@gmail.com"
  @credentials %{
    "email" => "budget@gmail.com",
    "password" => AuthService.hash_password("password11"),
    "active" => false
  }
  @login_input %{
    "email" => "budget@gmail.com",
    "password" => "password11"
  }
  @budget_input %{
    "income_source" => "Check",
    "budget_amount" => 60000,
    "current_month" => 5,
    "current_year" => 2019
  }
  @budget_post_result %{
    "budget" => %{
      "account_balance" => 0,
      "budget_exceeded" => false,
      "budget_set" => true,
      "current_budget" => 60000
    },
    "current_month" => 5,
    "current_year" => 2019,
    "message" => "Successfully set your budget for the month.",
    "updated_month_data" => %{
      "budget" => 60000,
      "budget_exceeded" => false,
      "deposits" => [],
      "necessary_expenses" => [],
      "total_deposited" => 0,
      "total_necessary_expenses" => 0,
      "total_unnecessary_expenses" => 0,
      "unnecessary_expenses" => []
    }
  }

  setup_all do
    BudgetServer.start_link(@guest_account)
    CredentialServer.create_credentials(@credentials)
    CredentialServer.activate_user(@credentials["email"])
  end

  test "POST /api/deposit", %{conn: conn} do
    conn = post(conn, "/api/login", @login_input)
    conn = post(conn, "/api/account", @budget_input)

    # Not testing that date is on the response currently
    # But it is there.
    assert @budget_post_result = json_response(conn, 200)
  end
end
