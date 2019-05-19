defmodule BudgetAppWeb.PageControllerTest do
  use BudgetAppWeb.ConnCase
  alias BudgetApp.AuthService
  alias BudgetApp.{BudgetServer}
  alias BudgetApp.{CredentialServer}

  @guest_account "guest@gmail.com"
  @credentials %{
    "email" => "guest@gmail.com",
    "password" => AuthService.hash_password("password11"),
    "active" => false
  }
  @login_input %{
    "email" => "guest@gmail.com",
    "password" => "password11"
  }
  @deposit_input %{
    "income_source" => "Check",
    "deposit_amount" => 400_000,
    "current_month" => 5,
    "current_year" => 2019
  }
  @deposit_post_result %{
    "account_balance" => 400_000,
    "amount" => 400_000,
    "category" => "DEPOSIT",
    "total_deposited" => 400_000,
    "type" => "Check"
  }

  setup_all do
    BudgetServer.start_link(@guest_account)
    CredentialServer.create_credentials(@credentials)
    CredentialServer.activate_user(@credentials["email"])
  end

  test "POST /api/deposit", %{conn: conn} do
    result =
      post(conn, "/api/login", @login_input)
      |> post("/api/deposit", @deposit_input)
      |> json_response(200)

    # Not testing that date is on the response currently
    # But it is there.
    assert @deposit_post_result = result
  end
end
