defmodule BudgetApp.Auth do
  import Plug.Conn

  use Timex
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
    %{email: email, remember_token: remember_token, expiry: expiry} =
      get_session(conn, :session_token)

    IO.puts("DID GET EMAIL AND REMEMBER TOKEN")
    IO.inspect(email)
    IO.inspect(remember_token)
    IO.puts("THE EXPIRY")
    IO.inspect(expiry)
    # cookie = fetch_cookies(conn)
    # IO.puts("RETRIEVED FROM fetch_cookies")
    # IO.inspect(cookie)
    datetime = Timex.now() |> DateTime.to_unix()

    case datetime < expiry do
      true ->
        fetch_user(conn, email, remember_token)

      false ->
        # TODO:
        # - Remove the remember_token from Credential GenServer state
        # - Clear session
        # - Send json structure to indicate to React SPA that
        #   user needs to be redirected to login page
        IO.puts("EXPIRY TIME HAS ELAPSED")
        conn = put_session(conn, :session_token, %{})
    end
  end

  def fetch_user(conn, email, remember_token) do
    case CredentialServer.get_user(email) do
      {:ok, user} ->
        auth_check(conn, user, remember_token)

      {:err, msg} ->
        # Unable to find user in GenServer State
        # msg will be "Invalid email or password."
        {:err, msg}
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
        # User's remember_token doesn't match
        {:err, "Invalid email or password."}
        # json(conn, %{message: "Invalid email or password."})
    end
  end

  def remember_token_matches?(
        %{"hashed_remember_token" => hashed_remember_token} = user,
        remember_token
      ) do
    IO.puts("incoming hashed token:")
    IO.inspect(AuthService.hash_remember_token(remember_token))
    IO.puts("stored hashed token:")
    IO.inspect(hashed_remember_token)
    AuthService.hash_remember_token(remember_token) === hashed_remember_token
  end

  def remember_token_matches?(_user, _remember_token) do
    false
  end
end
