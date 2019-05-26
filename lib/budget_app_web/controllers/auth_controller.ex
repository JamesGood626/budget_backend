defmodule BudgetAppWeb.AuthController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetSupervisor
  alias BudgetApp.{BudgetServer, CredentialServer}
  alias BudgetApp.AuthService
  alias BudgetApp.Email

  def csrf(conn, _params) do
    csrf_token = get_csrf_token()
    IO.puts("A CSRF TOKEN:")
    IO.inspect(csrf_token)
    json(conn, %{csrf_token: csrf_token})
  end

  def signup(conn, %{"email" => email, "password" => password} = params) do
    IO.puts("SIGNUP ROUTE HIT")
    # All of these should really be delegated to some service functions.
    case CredentialServer.get_user(email) do
      {:ok, _user} ->
        # status code?
        json(conn, %{message: "That email is taken."})

      # Move all this logic into the Auth Module
      {:err, _message} ->
        hash = AuthService.hash_password(password)

        Map.put(params, "password", hash)
        |> Map.put_new("active", false)
        |> CredentialServer.create_credentials()

        short_token = AuthService.generate_short_token()
        CredentialServer.add_short_token(email, short_token)
        Email.send_signup_email(short_token, email)
        json(conn, %{message: "you've successfully requested to sign up #{email}"})
    end
  end

  def approve_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email}) do
    # All of these should really be delegated to some service functions.
    {:ok, user} = CredentialServer.get_user(user_email)

    case user["short_token"] === short_token do
      true ->
        # Move all this to a separate function (/Auth Module) which uses a when block?
        CredentialServer.remove_short_token(user_email)
        CredentialServer.activate_user(user_email)
        BudgetSupervisor.start_budget(user_email)
        Email.send_notify_email(user_email)
        json(conn, %{message: "you've successfully approved the sign up"})

      false ->
        json(conn, %{message: "Invalid short token!"})
    end
  end

  def deny_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email}) do
    # All of these should really be delegated to some service functions.
    CredentialServer.remove_user(user_email)
    json(conn, %{message: "you've successfully denied the sign up!"})
  end

  def login(conn, %{"email" => email, "password" => password} = params) do
    AuthService.login_user(conn, params)
  end

  def logout(conn, _params) do
    %{email: email} = get_session(conn, :session_token)

    case CredentialServer.remove_hashed_remember_token(email) do
      {:ok, _msg} ->
        conn
        |> put_session(:session_token, %{})
        |> json(%{message: "Logout Success!"})

      {:err, _msg} ->
        json(conn, %{message: "Logout Failed!"})
    end
  end
end
