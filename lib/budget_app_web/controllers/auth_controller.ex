defmodule BudgetAppWeb.AuthController do
  use BudgetAppWeb, :controller
  alias BudgetApp.BudgetSupervisor
  alias BudgetApp.{BudgetServer, CredentialServer}
  alias BudgetApp.AuthService
  alias BudgetApp.Email

  def signup(conn, %{"email" => email, "password" => password} = params) do
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

  def login(conn, %{"email" => email, "password" => password}) do
    # TODO
    # Do the remember token stuff
    case CredentialServer.get_user(email) do
      {:ok, user} ->
        case AuthService.check_user_password(user, email, password) do
          {:ok, session_data} ->
            conn = put_session(conn, :session_token, session_data)
            json(conn, %{message: "Login Success!"})

          {:err, message} ->
            json(conn, %{message: message})
        end

      {:err, message} ->
        json(conn, %{message: message})
    end
  end

  def logout(conn, _params) do
    # Tried clear_session.1 | delete_session/2 | configure_session(conn, :drop)
    # None of the above worked to clear the cookie from the conn session. However,
    # just removing the remember token alone does force the user to sign in again.
    # but still want to look into this later.
    %{email: email} = get_session(conn, :session_token)

    case CredentialServer.remove_hashed_remember_token(email) do
      {:ok, _msg} ->
        json(conn, %{message: "Logout Success!"})

      {:err, _msg} ->
        json(conn, %{message: "Logout Failed!"})
    end
  end
end
