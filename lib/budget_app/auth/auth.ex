defmodule BudgetApp.Auth do
  import Plug.Conn

  alias BudgetApp.CredentialServer
  alias BudgetApp.AuthService

  # halt isn't enough, need to send a json response.
  def authorize_user(conn, _opts) do
    %{email: email, remember_token: remember_token} = get_session(conn, :session_token)

    case CredentialServer.get_user(email) do
      {:ok, user} ->
        auth_check(conn, user, remember_token)

      {:err, msg} ->
        # Or send a json response instead?
        halt(conn)
    end
  end

  # Still need to add issued_at_time (iat) to the cookie as well
  # to invalidate cookie after certain amount of time.
  def auth_check(conn, user, remember_token) do
    case remember_token_matches?(user, remember_token) do
      true ->
        IO.puts("USERS REMEMBER TOKEN MATCHES")
        assign(conn, :current_user, user["email"])

      false ->
        IO.puts("USERS REMEMBER TOKEN DOESN'T MATCH")
        halt(conn)
    end
  end

  def remember_token_matches?(
        %{"hashed_remember_token" => hashed_remember_token} = user,
        remember_token
      ) do
    AuthService.hash_remember_token(remember_token) === hashed_remember_token
  end

  def remember_token_matches?(_user, _remember_token) do
    false
  end
end
