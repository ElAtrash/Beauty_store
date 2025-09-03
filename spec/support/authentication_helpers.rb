module AuthenticationHelpers
  def authenticate_as(user)
    session = user.sessions.create!(
      user_agent: "Test User Agent",
      ip_address: "127.0.0.1"
    )

    cookies.signed[:session_id] = {
      value: session.id,
      httponly: true,
      same_site: :lax
    }

    allow(Current).to receive(:session).and_return(session)
  end

  def bypass_authentication
    allow_any_instance_of(ApplicationController).to receive(:require_authentication)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(true)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(true)

    allow_any_instance_of(ApplicationController).to receive(:find_session_by_cookie).and_return(nil)

    allow(Current).to receive(:session).and_return(nil)
  end

  def create_test_user
    create(:user, email_address: "test@example.com", password: "password123")
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelpers, type: :request
  config.include AuthenticationHelpers, type: :system
end
