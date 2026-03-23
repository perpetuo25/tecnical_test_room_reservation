require "rails_helper"

RSpec.describe "Api::V1::Reservations", type: :request do
  describe "POST /api/v1/reservations" do
    it "creates a reservation when the payload is valid" do
      room = create(:room)
      user = create(:user)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Planning",
          starts_at: "2026-02-02T10:00:00Z",
          ends_at: "2026-02-02T14:00:00Z"
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body.dig("data", "title")).to eq("Planning")
      expect(Reservation.count).to eq(1)
    end

    it "returns validation errors for overlapping reservations" do
      room = create(:room)
      user = create(:user)
      other_user = create(:user)

      create(
        :reservation,
        room: room,
        user: user,
        starts_at: Time.zone.parse("2026-02-02 10:00:00 UTC"),
        ends_at: Time.zone.parse("2026-02-02 11:00:00 UTC")
      )

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: other_user.id,
          title: "Conflicting meeting",
          starts_at: "2026-02-02T10:30:00Z",
          ends_at: "2026-02-02T11:30:00Z"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "message")).to eq("Validation failed")
      expect(response.parsed_body.dig("error", "details")).to include("room already has an active reservation for that time")
    end

    it "returns a bad request error when the payload root is missing" do
      post "/api/v1/reservations", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]["message"]).to include("param is missing")
    end
  end

  describe "PATCH /api/v1/reservations/:id/cancel" do
    it "marks the reservation as cancelled" do
      reservation = create(:reservation, cancelled_at: nil)

      patch "/api/v1/reservations/#{reservation.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "cancelled_at")).to be_present
      expect(reservation.reload.cancelled_at).to be_present
    end
  end
end
