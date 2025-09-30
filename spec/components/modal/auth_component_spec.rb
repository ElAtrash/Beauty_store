# frozen_string_literal: true

RSpec.describe Modal::AuthComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:user) { double('user', name: 'John Doe', email_address: 'john@example.com') }
  let(:component_signed_out) { described_class.new(current_user: nil) }
  let(:component_signed_in) { described_class.new(current_user: user) }

  describe "initialization" do
    it "sets default modal properties" do
      component = described_class.new
      expect(component.id).to eq("auth")
      expect(component.size).to eq(:medium)
      expect(component.position).to eq(:right)
    end

    it "accepts current_user parameter" do
      component = described_class.new(current_user: user)
      expect(component.send(:current_user)).to eq(user)
    end

    it "handles nil current_user" do
      component = described_class.new(current_user: nil)
      expect(component.send(:current_user)).to be_nil
    end
  end

  describe "signed out state" do
    let(:component) { component_signed_out }

    it "detects signed out state" do
      expect(component.send(:signed_in?)).to be false
    end

    it "renders login form content" do
      # Test the content within a proper rendering context
      rendered = render_inline(component)
      content_element = rendered.css("#auth-content")
      expect(content_element.text).to include("Email address")
      expect(content_element.text).to include("Password")
      expect(content_element.text).to include("Sign In")
    end

    it "provides eye icon paths for password visibility" do
      # The component should have these private methods
      expect(component.private_methods).to include(:eye_icon_path)
      expect(component.private_methods).to include(:eye_off_icon_path)
    end

    it "renders with empty title" do
      expect(component.title).to eq("")
    end
  end

  describe "signed in state" do
    let(:component) { component_signed_in }

    it "detects signed in state" do
      expect(component.send(:signed_in?)).to be true
    end

    it "renders user menu content" do
      # Test the content within a proper rendering context
      rendered = render_inline(component)
      content_element = rendered.css("#auth-content")
      expect(content_element.text).to include("Welcome back")
      expect(content_element.text).to include("john@example.com")
    end

    it "provides user menu items" do
      expect(component.private_methods).to include(:user_menu_items)
    end

    it "renders with empty title" do
      expect(component.title).to eq("")
    end
  end

  describe "content rendering" do
    context "when signed out" do
      let(:component) { component_signed_out }

      # No mocking needed - use real component behavior

      it "renders login form" do
        rendered = render_inline(component)
        # Check for actual login form elements instead of mock content
        expect(rendered.css("#auth-content").text).to include("Sign In")
        expect(rendered.css("#auth-content").text).to include("Email address")
        expect(rendered.css("#auth-content").text).to include("Password")
      end
    end

    context "when signed in" do
      let(:component) { component_signed_in }

      # No mocking needed - use real component behavior

      it "renders user menu" do
        rendered = render_inline(component)
        # Check for actual user menu elements instead of mock content
        expect(rendered.css("#auth-content").text).to include("Welcome back")
        expect(rendered.css("#auth-content").text).to include("john@example.com")
      end
    end
  end

  describe "rendering integration" do
    let(:component) { component_signed_out }

    before do
      allow(component).to receive(:eye_icon_path).and_return("/icons/eye.svg")
      allow(component).to receive(:eye_off_icon_path).and_return("/icons/eye-off.svg")

      # Mock UI::IconComponent for base template
      allow(UI::IconComponent).to receive(:new).and_return(double("icon", render_in: "<svg>icon</svg>"))

      # Mock the content method instead of render
      allow(component).to receive(:content).and_return("Auth content")
    end

    it "renders complete modal structure" do
      rendered = render_inline(component)

      # Check modal structure
      expect(rendered.css("div[id='auth']")).to be_present
      expect(rendered.css("h2").text.strip).to be_empty # Empty title

      # Check content area
      expect(rendered.css("#auth-content")).to be_present
    end

    it "inherits all base modal functionality" do
      rendered = render_inline(component)

      # Should have all base modal features
      expect(rendered.css("[data-modal-target='overlay']")).to be_present
      expect(rendered.css("[data-modal-target='panel']")).to be_present
      expect(rendered.css("button[data-action='click->modal#close']")).to be_present
      expect(rendered.css("[data-controller]").first.attributes["data-controller"].value).to include("modal")
    end

    it "uses right position by default" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("right-0")
    end

    it "uses medium size by default" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("w-[680px]")
    end
  end

  describe "state transitions" do
    it "handles switching from signed out to signed in" do
      # Test that component behavior changes based on current_user
      signed_out_component = described_class.new(current_user: nil)
      signed_in_component = described_class.new(current_user: user)

      expect(signed_out_component.send(:signed_in?)).to be false
      expect(signed_in_component.send(:signed_in?)).to be true
    end
  end

  describe "accessibility" do
    let(:component) { component_signed_out }

    it "includes proper ARIA attributes" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='auth']").first

      expect(modal_div.attributes["role"].value).to eq("dialog")
      expect(modal_div.attributes["aria-modal"].value).to eq("true")
      expect(modal_div.attributes["aria-labelledby"].value).to eq("auth-title")
    end
  end

  describe "responsive design" do
    let(:component) { component_signed_out }

    it "includes mobile-responsive classes" do
      rendered = render_inline(component)
      expect(rendered.to_html).to include("max-md:w-full")
      expect(rendered.to_html).to include("sm:px-12")
    end
  end

  describe "icon paths" do
    let(:component) { component_signed_out }

    # These would typically be implemented in the component or a helper
    it "provides methods for eye icon paths" do
      expect(component.private_methods).to include(:eye_icon_path)
      expect(component.private_methods).to include(:eye_off_icon_path)
    end
  end

  describe "user menu items" do
    let(:component) { component_signed_in }

    # This would typically be implemented to return navigation items
    it "provides method for user menu items" do
      expect(component.private_methods).to include(:user_menu_items)
    end
  end

  describe "modal data attributes" do
    let(:component) { component_signed_out }

    it "includes standard modal data attributes" do
      rendered = render_inline(component)
      modal_div = rendered.css("div[id='auth']").first

      expect(modal_div.attributes["data-controller"].value).to include("modal")
      expect(modal_div.attributes["data-modal-id-value"].value).to eq("auth")
      expect(modal_div.attributes["data-modal-backdrop-close-value"].value).to eq("true")
    end
  end
end
