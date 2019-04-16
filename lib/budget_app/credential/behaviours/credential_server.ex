defmodule BudgetApp.CredentialServer do
  # The child process is restarted only if it terminates abnormally,
  # i.e. with an exit reason other than :normal, :shutdown, or {:shutdown, term}
  use GenServer, restart: :transient
  alias BudgetApp.Credential

  def start_link(_opts) do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    {:ok, %{}}
  end

  def get_state do
    GenServer.call(__MODULE__, {:get_state})
  end

  def create_credentials(credentials) do
    GenServer.cast(__MODULE__, {:create_credentials, credentials})
  end

  def get_user(email) do
    GenServer.call(__MODULE__, {:get_user, email})
  end

  def remove_user(email) do
    GenServer.cast(__MODULE__, {:remove_user, email})
  end

  def clear_state() do
    GenServer.cast(__MODULE__, {:clear_state})
  end

  def add_short_token(email, short_token) do
    GenServer.cast(__MODULE__, {:add_short_token, {email, short_token}})
  end

  def remove_short_token(email) do
    GenServer.cast(__MODULE__, {:remove_short_token, email})
  end

  def activate_user(email) do
    GenServer.cast(__MODULE__, {:activate_user, email})
  end

  def handle_call({:get_state}, _from, state) do
    {:reply, state, state}
  end

  # All of the handle_call/handle_casts need to be made more resilient to errors.
  def handle_call({:get_user, email}, _from, state) do
    %{^email => credentials} = state
    {:reply, credentials, state}
  end

  def handle_cast({:remove_user, email}, state) do
    new_state = Map.delete(state, email)
    {:noreply, new_state}
  end

  def handle_cast({:clear_state}, state) do
    {:noreply, %{}}
  end

  def handle_cast({:create_credentials, credentials}, state) do
    IO.puts("IN CREATE CREDENTIALS HANDLE CAST")
    %{"email" => email} = credentials
    new_state = Map.put_new(state, email, credentials)
    {:noreply, new_state}
  end

  def handle_cast({:add_short_token, {email, short_token}}, state) do
    %{^email => credentials} = state
    updated_credentials = Map.put_new(credentials, "short_token", short_token)
    updated_state = Map.put(state, email, updated_credentials)
    {:noreply, updated_state}
  end

  def handle_cast({:remove_short_token, email}, state) do
    %{^email => credentials} = state
    old_credentials = Map.fetch(state, email)
    updated_credentials = Map.delete(old_credentials, "short_token")
    updated_state = Map.put(state, email, updated_credentials)
    {:noreply, updated_state}
  end

  def handle_cast({:activate_user, email}, state) do
    {:ok, old_credentials} = Map.fetch(state, email)
    updated_credentials = Map.put(old_credentials, "active", true)

    new_state = Map.put(state, email, updated_credentials)
    {:noreply, new_state}
  end
end
