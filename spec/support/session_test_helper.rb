module SessionTestHelper
  def sign_in_as(user)
    # Create a session for the user
    session = user.sessions.create!(
      user_agent: try(:request)&.user_agent || "Test Agent",
      ip_address: try(:request)&.remote_ip || "127.0.0.1"
    )

    # For request specs (Rack::Test), we need to manually sign the cookie
    # Since ActionDispatch::Cookies::SignedKeyRotatingCookieJar isn't available,
    # we'll stub the authentication
    if defined?(cookies) && cookies.respond_to?(:signed)
      # Integration/System tests - use signed cookies
      cookies.signed[:session_id] = {
        value: session.id,
        httponly: true,
        same_site: :lax
      }
    else
      # Request specs - stub Current.session directly
      allow(Current).to receive(:session).and_return(session)
      allow(Current).to receive(:user).and_return(user)
    end

    # Set Current.session for the request context
    Current.session = session
  end

  def sign_out
    Current.session&.destroy
    cookies.delete(:session_id)
    Current.session = nil
  end

  def current_user
    Current.user
  end

  # Additional helper for Rails 8 authentication testing
  def bypass_authentication_for_tests
    # Override authentication methods to allow unauthenticated access
    allow_any_instance_of(ApplicationController).to receive(:require_authentication).and_return(nil)
    allow_any_instance_of(ApplicationController).to receive(:authenticated?).and_return(false)
    allow_any_instance_of(ApplicationController).to receive(:resume_session).and_return(nil)
    # Disable host authorization for tests
    allow_any_instance_of(ApplicationController).to receive(:ensure_valid_host).and_return(nil)
    # Skip any authentication-related before_actions
    ApplicationController.skip_before_action :require_authentication, raise: false
  end

  # Helper to directly stub Current.session for tests
  def stub_current_session(session = nil)
    allow(Current).to receive(:session).and_return(session)
  end
end
