require "rails_helper"

RSpec.describe "Api::V1::Reservations", type: :request do
  describe "GET /api/v1/reservations" do
    it "returns a paginated list of reservations" do
      create_list(:reservation, 3)

      get "/api/v1/reservations", params: { page: 1, per_page: 2 }

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

  describe "GET /api/v1/reservations/:id" do
    it "returns a reservation with its room and user" do
      reservation = create(:reservation)

      get "/api/v1/reservations/#{reservation.id}"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "id")).to eq(reservation.id)
      expect(response.parsed_body.dig("data", "room", "id")).to eq(reservation.room_id)
      expect(response.parsed_body.dig("data", "user", "id")).to eq(reservation.user_id)
    end
  end

  describe "POST /api/v1/reservations" do
    it "creates a reservation within the regular user's capacity" do
      room = create(:room, capacity: 8)
      user = create(:user, max_capacity_allowed: 8)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Planning",
          starts_at: 1.day.from_now.change(hour: 10),
          ends_at: 1.day.from_now.change(hour: 11)
        }
      }

      expect(response).to have_http_status(:created)
    end

    it "rejects a room above the regular user's capacity limit" do
      room = create(:room, capacity: 12)
      user = create(:user, max_capacity_allowed: 8)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Planning",
          starts_at: 1.day.from_now.change(hour: 10),
          ends_at: 1.day.from_now.change(hour: 11)
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("Room capacity exceeds the user's limit")
    end

    it "rejects a fourth active future reservation for a regular user" do
      user = create(:user)
      room = create(:room, capacity: user.max_capacity_allowed)
      create_list(:reservation, 3, user: user, room: room)

      other_room = create(:room, capacity: user.max_capacity_allowed)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: other_room.id,
          user_id: user.id,
          title: "Fourth reservation",
          starts_at: 2.days.from_now.change(hour: 10),
          ends_at: 2.days.from_now.change(hour: 11)
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("User cannot have more than 3 active future reservations")
    end

    it "allows admins to bypass both reservation restrictions" do
      admin = create(:user, :admin, max_capacity_allowed: 1)
      create_list(:reservation, 4, user: admin, room: create(:room, capacity: 20))
      room = create(:room, capacity: 30)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: admin.id,
          title: "Executive meeting",
          starts_at: 3.days.from_now.change(hour: 10),
          ends_at: 3.days.from_now.change(hour: 11)
        }
      }

      expect(response).to have_http_status(:created)
    end
  end
end
