defmodule BudgetApp.AuthService do
  # Will switch these over to be functions that return the env_var value at runtime,
  # after I've confirmed that cookie signup/login flow works with these static values.
  @key "Thestrongestkeyever"
  @remember_token_bytes 32
  use BudgetAppWeb, :controller
  use Timex
  alias BudgetApp.CredentialServer

  def generate_short_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.url_encode64()
  end

  def generate_remember_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.encode64()
  end

  def hash_remember_token(remember_token) do
    :crypto.hmac(:sha256, @key, remember_token) |> Base.encode64()
  end

  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end

  def generate_expiry_time(session_data) do
    # To facilitate testing this, it would be ideal
    # to inject the values for days and hours
    expiry =
      Timex.now()
      |> Timex.shift(days: 1, hours: 12)
      |> DateTime.to_unix()

    Map.put(session_data, :expiry, expiry)
  end

  def login_user(conn, %{"email" => email, "password" => password} = params) do
    case CredentialServer.get_user(email) do
      {:ok, user} ->
        check_user_password_or_fail(conn, user, email, password)

      {:err, message} ->
        json(conn, %{message: message})
    end
  end

  def check_user_password(user, email, password) do
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

  def check_user_password_or_fail(conn, user, email, password) do
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

        json(conn, %{message: "Login Success!"})

      {:err, message} ->
        json(conn, %{message: message})
    end
  end
end

# BudgetAppWeb.Router.Helpers.approved_short_token_url(BudgetApp.Endpoint,
#         :approve_sign_up, short_token: @short_token)
