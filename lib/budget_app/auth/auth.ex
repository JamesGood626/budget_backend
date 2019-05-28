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
    get_session(conn, :session_token)
    |> authorize(conn)
  end

  def authorize(nil, conn), do: assign(conn, :current_user, nil)

  def authorize(%{expiry: expiry} = params, conn) do
    Timex.now()
    |> DateTime.to_unix()
    |> check_expiry(expiry, params, conn)
  end

  def check_expiry(datetime, expiry, %{email: email, remember_token: remember_token}, conn) do
    case datetime < expiry do
      true ->
        fetch_user(conn, email, remember_token)

      false ->
        # IO.puts("EXPIRY TIME HAS ELAPSED")
        delete_session(conn, :session_token)
        |> assign(:current_user, nil)
    end
  end

  def fetch_user(conn, email, remember_token) do
    case CredentialServer.get_user(email) do
      {:ok, user} ->
        auth_check(conn, user, remember_token)

      {:err, message} ->
        # Unable to find user in GenServer State
        # message will be "Invalid email or password."
        {:err, message}
    end
  end

  def auth_check(conn, user, remember_token) do
    case remember_token_matches?(user, remember_token) do
      true ->
        assign(conn, :current_user, user["email"])

      false ->
        # User's remember_token doesn't match
        {:err, "Invalid email or password."}
    end
  end

  @doc """
    remember_token is the incoming token from the request.

    hashed_remember_token is the one that was stored in Credential
    GenServer state.
  """
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
