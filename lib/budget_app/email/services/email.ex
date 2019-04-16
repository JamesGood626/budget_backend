defmodule BudgetApp.Email do
  use Bamboo.Phoenix, view: BudgetApp.EmailView
  alias BudgetApp.Auth

  # How to test the user flow for this process? I assume that to test this would require End-to-End.
  def welcome_text_email(email_address) do
    new_email
    |> to(email_address)
    |> from("us@exmaple.com")
    |> subject("Welcome!")
    |> text_body("Welcome to Budget Slayer 9000!")
  end

  def send_signup_email(short_token, user_email) do
    signup_request_email("jamesgood626@gmail.com", short_token, user_email)
    |> BudgetApp.Mailer.deliver_now()
  end

  def send_notify_email(user_email) do
    notify_signup_success_email("jamesgood626@gmail.com", user_email)
    |> BudgetApp.Mailer.deliver_now()
  end

  def signup_request_email(sender_email, short_token, user_email) do
    # Utilize GenServer for storing credentials temporarily
    # - these credentials will be kept if I approve sign up
    # - ELSE, they will be removed upon denial of signup request
    # - The ip address of the failed signup request will also be
    #   blacklisted so that they can't send multiple signup requests
    base_email
    |> to("james.good@codeimmersives.com")
    |> from(sender_email)
    |> subject("Sign Up Requested")
    # Need to generate url short token with the :crypto package
    # so that the short token will be stored w/ the credentials
    # in the GenServer to match up the incoming approve signup
    # POSt request, as a way of mitigating malicious users from
    # attempting to approve their own requests.
    |> assign(:user_email, user_email)
    |> assign(:short_token, short_token)
    |> render("sign_up_request.html")
  end

  def notify_signup_success_email(sender_email, user_email) do
    base_email
    |> to(user_email)
    |> from(sender_email)
    |> subject("You're Signed Up!")
    |> render("notify_approved_request.html")
  end

  # short_token: "shortToken"
  def base_email do
    new_email
    |> put_html_layout({BudgetApp.EmailView, "email.html"})
  end
end
