# frozen_string_literal: true

RSpec.describe "Addresses", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let!(:user_address) { create(:address, user: user, label: "Home", default: true) }
  let!(:work_address) { create(:address, user: user, label: "Work") }
  let!(:other_user_address) { create(:address, user: other_user, label: "Other User Home") }

  describe "Authentication" do
    context "when user is not logged in" do
      it "redirects GET /addresses to login" do
        get addresses_path
        expect(response).to redirect_to(new_session_path)
      end

      it "redirects POST /addresses to login" do
        post addresses_path, params: { address: { label: "Home" } }
        expect(response).to redirect_to(new_session_path)
      end
    end
  end

  describe "GET /addresses" do
    before { sign_in_as(user) }

    it "returns successful response" do
      get addresses_path
      expect(response).to have_http_status(:success)
    end

    it "lists only user's active addresses" do
      deleted_address = create(:address, user: user, label: "Deleted")
      deleted_address.soft_delete

      get addresses_path

      expect(response.body).to include(user_address.label)
      expect(response.body).to include(work_address.label)
      expect(response.body).not_to include(deleted_address.label)
      expect(response.body).not_to include(other_user_address.label)
    end

    it "orders addresses by recently used" do
      # Create addresses with specific timestamps to ensure proper ordering
      old_address = create(:address, user: user, label: "Old Address", updated_at: 1.day.ago)
      recent_address = create(:address, user: user, label: "Recent Address", updated_at: 1.hour.ago)

      get addresses_path
      expect(response.body.index(recent_address.display_label)).to be < response.body.index(old_address.display_label)
    end
  end

  describe "GET /addresses/new" do
    before { sign_in_as(user) }

    it "returns successful response" do
      get new_address_path
      expect(response).to have_http_status(:success)
    end

    it "assigns a new address" do
      get new_address_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("new-address")
    end
  end

  describe "POST /addresses" do
    before { sign_in_as(user) }

    let(:valid_params) do
      {
        address: {
          label: "Parents",
          address_line_1: "789 Family Street",
          address_line_2: "Villa 3",
          city: "Tripoli",
          governorate: "North Lebanon",
          landmarks: "Near the old mosque",
          phone_number: "70555444",
          default: false
        }
      }
    end

    context "with valid parameters" do
      it "creates a new address" do
        expect {
          post addresses_path, params: valid_params
        }.to change(user.addresses, :count).by(1)
      end

      it "sets correct attributes" do
        post addresses_path, params: valid_params

        address = user.addresses.last
        expect(address.label).to eq("Parents")
        expect(address.address_line_1).to eq("789 Family Street")
        expect(address.city).to eq("Tripoli")
        expect(address.governorate).to eq("North Lebanon")
        expect(address.default).to be_falsey
      end

      it "responds with turbo stream", :aggregate_failures do
        post addresses_path, params: valid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("addresses-list")
      end

      it "responds with redirect for html", :aggregate_failures do
        post addresses_path, params: valid_params

        expect(response).to redirect_to(addresses_path)
        expect(flash[:notice]).to eq(I18n.t("addresses.created"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { address: { label: "", address_line_1: "" } }
      end

      it "does not create address" do
        expect {
          post addresses_path, params: invalid_params
        }.not_to change(Address, :count)
      end

      it "responds with unprocessable entity for turbo stream" do
        post addresses_path, params: invalid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "re-renders form for html" do
        post addresses_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with duplicate label" do
      it "rejects duplicate label for same user" do
        duplicate_params = valid_params.deep_merge(address: { label: "Home" })

        expect {
          post addresses_path, params: duplicate_params
        }.not_to change(Address, :count)
      end
    end

    context "when setting as default" do
      let(:default_params) { valid_params.deep_merge(address: { default: true }) }

      it "unsets previous default" do
        expect(user_address.reload.default).to be_truthy

        post addresses_path, params: default_params

        expect(user_address.reload.default).to be_falsey
        expect(user.addresses.last.default).to be_truthy
      end
    end
  end

  describe "GET /addresses/:id/edit" do
    before { sign_in_as(user) }

    it "returns successful response for turbo stream" do
      get edit_address_path(user_address), headers: { "Accept" => "text/vnd.turbo-stream.html" }
      expect(response).to have_http_status(:success)
    end

    it "responds with turbo stream replacement" do
      get edit_address_path(user_address), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("address-#{user_address.id}")
    end

    it "prevents accessing other user's address" do
      get edit_address_path(other_user_address)

      expect(response).to redirect_to(addresses_path)
      expect(flash[:alert]).to eq(I18n.t("addresses.not_found"))
    end
  end

  describe "PATCH /addresses/:id" do
    before { sign_in_as(user) }

    let(:update_params) do
      {
        address: {
          label: "Home Updated",
          address_line_1: "999 New Street",
          city: "Sidon",
          governorate: "South Lebanon"
        }
      }
    end

    context "with valid parameters" do
      it "updates the address" do
        patch address_path(user_address), params: update_params

        user_address.reload
        expect(user_address.label).to eq("Home Updated")
        expect(user_address.address_line_1).to eq("999 New Street")
        expect(user_address.city).to eq("Sidon")
      end

      it "responds with turbo stream" do
        patch address_path(user_address), params: update_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("address-#{user_address.id}")
      end

      it "redirects for html format" do
        patch address_path(user_address), params: update_params

        expect(response).to redirect_to(addresses_path)
        expect(flash[:notice]).to eq(I18n.t("addresses.updated"))
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { address: { address_line_1: "" } }
      end

      it "does not update address" do
        expect {
          patch address_path(user_address), params: invalid_params
        }.not_to change { user_address.reload.address_line_1 }
      end

      it "responds with unprocessable entity" do
        patch address_path(user_address), params: invalid_params, headers: { "Accept" => "text/vnd.turbo-stream.html" }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    it "prevents updating other user's address" do
      patch address_path(other_user_address), params: update_params

      expect(response).to redirect_to(addresses_path)
      expect(flash[:alert]).to eq(I18n.t("addresses.not_found"))
    end
  end

  describe "DELETE /addresses/:id" do
    before { sign_in_as(user) }

    context "when user has multiple addresses" do
      it "soft deletes the address" do
        expect {
          delete address_path(work_address)
        }.not_to change(Address, :count)

        expect(work_address.reload.deleted?).to be_truthy
      end

      it "responds with turbo stream" do
        delete address_path(work_address), headers: { "Accept" => "text/vnd.turbo-stream.html" }

        expect(response).to have_http_status(:success)
        expect(response.media_type).to eq(Mime[:turbo_stream])
        expect(response.body).to include("address-edit-#{work_address.id}")
      end

      it "redirects for html format" do
        delete address_path(work_address)

        expect(response).to redirect_to(addresses_path)
        expect(flash[:notice]).to eq(I18n.t("addresses.deleted"))
      end
    end

    context "when deleting only address" do
      before do
        work_address.soft_delete
      end

      it "allows deletion" do
        delete address_path(user_address)

        expect(user_address.reload.deleted?).to be_truthy
      end

      it "redirects for html format" do
        delete address_path(user_address)

        expect(response).to redirect_to(addresses_path)
        expect(flash[:notice]).to eq(I18n.t("addresses.deleted"))
      end
    end

    it "prevents deleting other user's address" do
      delete address_path(other_user_address)

      expect(response).to redirect_to(addresses_path)
      expect(flash[:alert]).to eq(I18n.t("addresses.not_found"))
    end
  end

  describe "PATCH /addresses/:id/set_default" do
    before { sign_in_as(user) }

    it "sets address as default" do
      expect(work_address.default).to be_falsey

      patch set_default_address_path(work_address)

      expect(work_address.reload.default).to be_truthy
    end

    it "unsets previous default" do
      expect(user_address.reload.default).to be_truthy

      patch set_default_address_path(work_address)

      expect(user_address.reload.default).to be_falsey
      expect(work_address.reload.default).to be_truthy
    end

    it "responds with turbo stream" do
      patch set_default_address_path(work_address), headers: { "Accept" => "text/vnd.turbo-stream.html" }

      expect(response).to have_http_status(:success)
      expect(response.media_type).to eq(Mime[:turbo_stream])
      expect(response.body).to include("addresses-list")
    end

    it "redirects for html format" do
      patch set_default_address_path(work_address)

      expect(response).to redirect_to(addresses_path)
      expect(flash[:notice]).to eq(I18n.t("addresses.set_as_default"))
    end

    it "prevents setting other user's address as default" do
      patch set_default_address_path(other_user_address)

      expect(response).to redirect_to(addresses_path)
      expect(flash[:alert]).to eq(I18n.t("addresses.not_found"))
    end
  end
end
