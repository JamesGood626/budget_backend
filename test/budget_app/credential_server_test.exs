defmodule CredentialServerTest do
  use ExUnit.Case, async: true
  alias BudgetApp.{CredentialServer}

  @credentials %{"email" => "jamesgood626@gmail.com", "password" => "test1234", "active" => false}
  @credentials_active %{
    "jamesgood626@gmail.com" => %{
      "active" => true,
      "email" => "jamesgood626@gmail.com",
      "password" => "test1234"
    }
  }
  @credentials_dos %{"email" => "random@gmail.com", "password" => "test1234"}
  # alias BudgetApp.CredentialServer
  # CredentialServer.start_link(%{})
  # credentials = %{email: "jamesgood626@gmail.com", password: "test1234"}
  # CredentialServer.create_credentials(credentials)

  setup_all do
    CredentialServer.start_link(%{})
    # The map returned in the tuple below can be pattern matched
    # on in the second argument of the test macro.
    {:ok, %{}}
  end

  setup do
    on_exit(fn ->
      CredentialServer.clear_state()
    end)

    {:ok, %{}}
  end

  test "credential server can create new credentials in internal state.", %{} do
    CredentialServer.create_credentials(@credentials)
    CredentialServer.create_credentials(@credentials_dos)
    credential_server_state = CredentialServer.get_state()

    assert credential_server_state === %{
             "jamesgood626@gmail.com" => @credentials,
             "random@gmail.com" => @credentials_dos
           }
  end

  test "credential server retrieve user's credentials from internal state.", %{} do
    CredentialServer.create_credentials(@credentials)

    user = CredentialServer.get_user(@credentials["email"])
    assert user === @credentials
  end

  test "credential server can add a short_token to a user's credentials.", %{} do
    CredentialServer.create_credentials(@credentials)
    CredentialServer.add_short_token(@credentials["email"], "da_short_token")
    credential_server_state = CredentialServer.get_state()

    updated_credentials = Map.put(@credentials, "short_token", "da_short_token")
    assert credential_server_state === %{"jamesgood626@gmail.com" => updated_credentials}
  end

  test "credential server can remove user credentials from state.", %{} do
    CredentialServer.create_credentials(@credentials)
    user = CredentialServer.get_user(@credentials["email"])
    assert user === @credentials

    CredentialServer.remove_user(@credentials["email"])
    credential_server_state = CredentialServer.get_state()
    assert credential_server_state === %{}
  end

  test "credential server can retrieve and activate user active status.", %{} do
    CredentialServer.create_credentials(@credentials)
    user = CredentialServer.get_user(@credentials["email"])
    assert user === @credentials

    CredentialServer.activate_user(@credentials["email"])
    credential_server_state = CredentialServer.get_state()

    assert credential_server_state === @credentials_active
  end
end
