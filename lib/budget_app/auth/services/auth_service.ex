defmodule BudgetApp.AuthService do
  # Will switch these over to be functions that return the env_var value at runtime,
  # after I've confirmed that cookie signup/login flow works with these static values.
  @key "Thestrongestkeyever"
  @remember_token_bytes 32
  use BudgetAppWeb, :controller
  use Timex
  alias BudgetApp.BudgetSupervisor
  alias BudgetApp.{BudgetServer, CredentialServer}
  alias BudgetApp.Email

  @bad_request 400

  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  def hash_remember_token(remember_token) do
    :crypto.hmac(:sha256, @key, remember_token) |> Base.encode64()
  end

  def signup_user(conn, %{"email" => email, "password" => password} = params) do
    case CredentialServer.get_user(email) do
      {:ok, _user} ->
        # status code?
        conn
        |> put_status(@bad_request)
        |> json(%{type: "EMAIL_TAKEN", message: "That email is taken."})

      # Move all this logic into the Auth Module
      {:err, _message} ->
        hash = hash_password(password)

        Map.put(params, "password", hash)
        |> Map.put_new("active", false)
        |> CredentialServer.create_credentials()

        short_token = generate_short_token()
        CredentialServer.add_short_token(email, short_token)
        Email.send_signup_email(short_token, email)
        # Was previously sending this -> "you've successfully requested to sign up #{email}"
        json(conn, %{message: "SIGNUP_SUCCESS"})
    end
  end

  def approve_sign_up(conn, %{"short_token" => short_token, "user_email" => user_email} = params) do
    {:ok, user} = CredentialServer.get_user(user_email)

    case user["short_token"] === short_token do
      true ->
        # Move all this to a separate function (/Auth Module) which uses a when block?
        # TODO: Use a with block to handle failure cases...
        CredentialServer.remove_short_token(user_email)
        CredentialServer.activate_user(user_email)
        BudgetSupervisor.start_budget(user_email)
        Email.send_notify_email(user_email)
        json(conn, %{message: "you've successfully approved the sign up"})

      false ->
        json(conn, %{message: "Invalid short token!"})
    end
  end

  def login_user(conn, %{"email" => email, "password" => password} = params) do
    email
    |> CredentialServer.get_user()
    |> login_response(conn, params)
  end

  def login_response({:ok, user}, conn, %{"email" => email, "password" => password} = params) do
    check_user_password_or_fail(conn, user, email, password)
  end

  def login_response({:err, message}, conn, _params), do: json(conn, %{message: message})

  def logout_user(conn) do
    %{email: email} = get_session(conn, :session_token)

    email
    |> CredentialServer.remove_hashed_remember_token()
    |> logout_response(conn)
  end

  def logout_response({:ok, _msg}, conn) do
    conn
    |> delete_session(:session_token)
    |> json(%{message: "LOGOUT_SUCCESS"})
  end

  def logout_response({:err, _msg}, conn), do: json(conn, %{message: "LOGOUT_FAIL"})

  #########################################
  defp generate_short_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.url_encode64()
  end

  defp generate_remember_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.encode64()
  end

  defp generate_expiry_time(session_data) do
    # To facilitate testing this, it would be ideal
    # to inject the values for days and hours
    expiry =
      Timex.now()
      |> Timex.shift(days: 1, hours: 12)
      |> DateTime.to_unix()

    Map.put(session_data, :expiry, expiry)
  end

  defp check_user_password(user, email, password) do
    case Bcrypt.verify_pass(password, user["password"]) and user["active"] do
      true ->
        remember_token = generate_remember_token()

        remember_token
        |> hash_remember_token()
        |> CredentialServer.add_hashed_remember_token(email)

        session_data =
          %{email: email, remember_token: remember_token}
          |> generate_expiry_time

        {:ok, session_data}

      false ->
        {:err, "Incorrect username or password!"}
    end
  end

  defp check_user_password_or_fail(conn, user, email, password) do
    case check_user_password(user, email, password) do
      {:ok, session_data} ->
        conn = put_session(conn, :session_token, session_data)
        # Remember to look into this. (Also a note left in auth.ex)
        # Just want to see how this approach differs from the route
        # I've chosen.
        #   put_resp_cookie(conn, "token", session_data.remember_token,
        #     # http_only: true,
        #     # secure: true,
        #     max_age: 604_800
        #   )

        json(conn, %{message: "LOGIN_SUCCESS"})

      {:err, message} ->
        json(conn, %{message: message})
    end
  end
end

# BudgetAppWeb.Router.Helpers.approved_short_token_url(BudgetApp.Endpoint,
#         :approve_sign_up, short_token: @short_token)
