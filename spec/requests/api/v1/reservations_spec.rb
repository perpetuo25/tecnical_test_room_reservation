require "rails_helper"

RSpec.describe "Api::V1::Reservations", type: :request do
  describe "PATCH /api/v1/reservations/:id/cancel" do
    it "marks the reservation as cancelled" do
      reservation = create(:reservation, cancelled_at: nil)

      patch "/api/v1/reservations/#{reservation.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "cancelled_at")).to be_present
      expect(reservation.reload.cancelled_at).to be_present
    end
  end

  describe "POST /api/v1/reservations" do
    it "returns a bad request error when the payload root is missing" do
      post "/api/v1/reservations", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]["message"]).to include("param is missing")
    end
  end
end
