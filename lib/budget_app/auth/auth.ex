defmodule BudgetApp.Auth do
  # Will switch these over to be functions that return the env_var value at runtime,
  # after I've confirmed that cookie signup/login flow works with these static values.
  @key "Thestrongestkeyever"
  @remember_token_bytes 32

  def generate_short_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.url_encode64()
  end

  def generate_remember_token do
    :crypto.strong_rand_bytes(@remember_token_bytes) |> Base.encode64()
  end

  def hash_remember_token(remember_token) do
    :crypto.hmac(:sha3_256, @key, remember_token) |> Base.encode64()
  end

  def hash_password(password) do
    Bcrypt.hash_pwd_salt(password)
  end
end

# BudgetAppWeb.Router.Helpers.approved_short_token_url(BudgetApp.Endpoint,
#         :approve_sign_up, short_token: @short_token)
