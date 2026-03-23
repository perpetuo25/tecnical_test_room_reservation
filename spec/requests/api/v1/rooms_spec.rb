require "rails_helper"

RSpec.describe "Api::V1::Rooms", type: :request do
  describe "GET /api/v1/rooms" do
    it "returns a paginated list of rooms" do
      create_list(:room, 3)

      get "/api/v1/rooms", params: { page: 1, per_page: 2 }

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

  describe "GET /api/v1/rooms/:id" do
    it "returns a room" do
      room = create(:room)

      get "/api/v1/rooms/#{room.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(room.id)
    end
  end

  describe "POST /api/v1/rooms" do
    it "creates a room for an admin user" do
      admin = create(:user, :admin)

      post "/api/v1/rooms", params: {
        admin_user_id: admin.id,
        room: {
          name: "Board Room",
          capacity: 12,
          has_projector: true,
          has_video_conference: true,
          floor: 4
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "name")).to eq("Board Room")
    end

    it "rejects a non-admin user" do
      user = create(:user)

      post "/api/v1/rooms", params: {
        user_id: user.id,
        room: {
          name: "Restricted Room",
          capacity: 8,
          has_projector: false,
          has_video_conference: false,
          floor: 2
        }
      }

      expect(response).to have_http_status(:forbidden)
      expect(response.parsed_body.dig("error", "message")).to eq("Admin access required")
    end
  end

  describe "GET /api/v1/rooms/:id/availability" do
    it "returns reservations for the given date" do
      room = create(:room)
      user = create(:user)

      reservation = create(
        :reservation,
        room: room,
        user: user,
        starts_at: Time.zone.parse("2026-02-02 10:00:00 UTC"),
        ends_at: Time.zone.parse("2026-02-02 11:00:00 UTC")
      )

      get "/api/v1/rooms/#{room.id}/availability", params: { date: "2026-02-02" }

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "date")).to eq("2026-02-02")
      expect(response.parsed_body.dig("data", "reservations").first["id"]).to eq(reservation.id)
    end
  end
end
