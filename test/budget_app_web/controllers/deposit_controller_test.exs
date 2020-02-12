defmodule BudgetAppWeb.DepositControllerTest do
  use BudgetAppWeb.ConnCase
  alias BudgetApp.AuthService
  alias BudgetApp.{BudgetServer}
  alias BudgetApp.{CredentialServer}

  {:ok, %{month: month}} = DateTime.now("Etc/UTC")

  @guest_account "deposit@gmail.com"
  @credentials %{
    "email" => "deposit@gmail.com",
    "password" => AuthService.hash_password("password11"),
    "active" => false
  }
  @login_input %{
    "email" => "deposit@gmail.com",
    "password" => "password11"
  }
  @deposit_input %{
    "income_source" => "Check",
    "deposit_amount" => 400_000,
    "current_month" => month,
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
    conn = post(conn, "/api/login", @login_input)
    conn = post(conn, "/api/deposit", @deposit_input)

    # Not testing that date is on the response currently
    # But it is there.
    assert @deposit_post_result = json_response(conn, 200)
  end
end
