require "rails_helper"

RSpec.describe "Api::V1::Rooms", type: :request do
  describe "GET /api/v1/rooms" do
    it "returns a paginated collection" do
      create_list(:room, 3)

      get "/api/v1/rooms", params: { page: 1, per_page: 2 }

      expect(response).to have_http_status(:ok)

      body = response.parsed_body

      expect(body["data"].size).to eq(2)
      expect(body["meta"]).to include(
        "page" => 1,
        "per_page" => 2,
        "total_count" => 3,
        "total_pages" => 2
      )
    end
  end

  describe "GET /api/v1/rooms/:id" do
    it "returns a JSON error when the room does not exist" do
      get "/api/v1/rooms/999999"

      expect(response).to have_http_status(:not_found)
      expect(response.parsed_body["error"]["message"]).to include("Couldn't find Room")
    end
  end

  describe "POST /api/v1/rooms" do
    it "creates a room" do
      post "/api/v1/rooms", params: {
        room: {
          name: "Focus Room",
          capacity: 6,
          has_projector: true,
          has_video_conference: false,
          floor: 2
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "name")).to eq("Focus Room")
    end
  end
end
