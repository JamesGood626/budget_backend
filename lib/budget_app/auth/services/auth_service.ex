defmodule BudgetApp.AuthService do
  # Will switch these over to be functions that return the env_var value at runtime,
  # after I've confirmed that cookie signup/login flow works with these static values.
  @key "Thestrongestkeyever"
  @remember_token_bytes 32
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

  def check_user_password(user, email, password) do
    case Bcrypt.verify_pass(password, user["password"]) and user["active"] do
      true ->
        # TODO: remember to invalidate token after a certain amount of time has elapsed.
        # Generate remember token, set remember token in cookie, and send success response
        remember_token = generate_remember_token()
        hashed_remember_token = hash_remember_token(remember_token)
        CredentialServer.add_hashed_remember_token(email, hashed_remember_token)
        {:ok, user} = CredentialServer.get_user(email)
        session_data = %{email: email, remember_token: remember_token}
        {:ok, session_data}

      false ->
        {:err, "Incorrect username or password!"}
    end
  end
end

# BudgetAppWeb.Router.Helpers.approved_short_token_url(BudgetApp.Endpoint,
#         :approve_sign_up, short_token: @short_token)
