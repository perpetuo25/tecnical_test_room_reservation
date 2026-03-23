require "rails_helper"

RSpec.describe "Api::V1::Users", type: :request do
  describe "GET /api/v1/users" do
    it "returns a paginated list of users" do
      create_list(:user, 3)

      get "/api/v1/users", params: { page: 1, per_page: 2 }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body["data"].size).to eq(2)
      expect(response.parsed_body["meta"]).to include(
        "page" => 1,
        "per_page" => 2,
        "total_count" => 3,
        "total_pages" => 2
      )
    end
  end

  describe "POST /api/v1/users" do
    it "creates a user" do
      post "/api/v1/users", params: {
        user: {
          name: "Alice",
          email: "alice@example.com",
          department: "Engineering",
          max_capacity_allowed: 8,
          is_admin: false
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "email")).to eq("alice@example.com")
    end
  end

  describe "GET /api/v1/users/:id" do
    it "returns a user" do
      user = create(:user)

      get "/api/v1/users/#{user.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(user.id)
    end
  end
end
