defmodule BudgetApp.Auth do
  import Plug.Conn

  alias BudgetApp.CredentialServer
  alias BudgetApp.AuthService

  # halt isn't enough, need to send a json response.
  # NOTE!!
  # When I attempted to use put_resp_cookie/4 in the AuthController login
  # function w/ options secure: true and httpOnly: true. -> axios
  # withCredentials = true couldn't access the cookies to send what was
  # set on the server in any future requests.
  # However... when using put_session/3 axios can send what was set just fine..
  # What is the underlying implementation of put_session/3?
  def authorize_user(conn, _opts) do
    %{email: email, remember_token: remember_token} = get_session(conn, :session_token)
    IO.puts("DID GET EMAIL AND REMEMBER TOKEN")
    IO.inspect(email)
    IO.inspect(remember_token)
    # cookie = fetch_cookies(conn)
    # IO.puts("RETRIEVED FROM fetch_cookies")
    # IO.inspect(cookie)

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
