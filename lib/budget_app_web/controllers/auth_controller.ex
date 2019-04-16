defmodule BudgetAppWeb.AuthController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetSupervisor
  alias BudgetApp.{BudgetServer, CredentialServer}
  alias BudgetApp.Auth
  alias BudgetApp.Email

  def signup(conn, %{"email" => email, "password" => password} = params) do
    # All of these should really be delegated to some service functions.

    hash = Auth.hash_password(password)

    Map.put(params, "password", hash)
    |> Map.put_new("active", false)
    |> CredentialServer.create_credentials()

    short_token = Auth.generate_short_token()
    CredentialServer.add_short_token(email, short_token)
    Email.send_signup_email(short_token, email)
    json(conn, %{message: "you've successfully requested to sign up #{email}"})
  end

  @spec approve_sign_up(Plug.Conn.t(), map()) :: Plug.Conn.t()
  def approve_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email}) do
    # All of these should really be delegated to some service functions.
    user = CredentialServer.get_user(user_email)

    case user["short_token"] === short_token do
      true ->
        CredentialServer.remove_short_token(user_email)
        CredentialServer.activate_user(user_email)
        BudgetSupervisor.start_budget(user_email)
        Email.send_notify_email(user_email)
        json(conn, %{message: "you've successfully approved the sign up"})

      false ->
        {:err, "Invalid short token."}
        json(conn, %{message: "Invalid short token."})
    end
  end

  def deny_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email}) do
    # All of these should really be delegated to some service functions.
    CredentialServer.remove_user(user_email)
    json(conn, %{message: "you've successfully denied the sign up"})
  end

  def login(conn, %{"email" => email, "password" => password}) do
    # TODO
    # Do the remember token stuff
    user = CredentialServer.get_user(email)

    case Bcrypt.verify_pass(password, user["password"]) and user["active"] do
      true ->
        # Generate remember token, set remember token in cookie, and send success response
        IO.puts("MATCHED PASSWORD")
        json(conn, %{message: "Login Success!"})

      false ->
        IO.puts("INVALID PASSWORD")
    end
  end

  def logout(conn, _params) do
    # TODO
    # remove the remember token hash from the GenServer state so that any subsequent requests will not be
    # Authorized.
  end
end
