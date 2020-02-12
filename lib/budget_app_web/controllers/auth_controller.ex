defmodule BudgetAppWeb.AuthController do
  use BudgetAppWeb, :controller
  alias BudgetApp.CredentialServer
  alias BudgetApp.AuthService

  # TODO: secret on the
  # client side so that only that particular
  # client may receive the csrf.
  def csrf(conn, _params) do
    # NOTE: There's also delete_csrf_token
    # handle that for signout
    csrf_token = get_csrf_token()
    json(conn, %{csrf_token: csrf_token})
  end

  def signup(conn, %{"email" => email, "password" => password} = params) do
    AuthService.signup_user(conn, params)
  end

  def approve_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email} = params) do
    AuthService.approve_sign_up(conn, params)
  end

  def deny_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email}) do
    CredentialServer.remove_user(user_email)
    json(conn, %{message: "you've successfully denied the sign up!"})
  end

  def login(conn, %{"email" => email, "password" => password} = params) do
    AuthService.login_user(conn, params)
  end

  def logout(conn, _params) do
    AuthService.logout_user(conn)
  end
end
