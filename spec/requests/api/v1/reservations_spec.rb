require "rails_helper"

RSpec.describe "Api::V1::Reservations", type: :request do
  describe "PATCH /api/v1/reservations/:id/cancel" do
    it "marks the reservation as cancelled" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 12, min: 0)
      reservation = create(
        :reservation,
        cancelled_at: nil,
        starts_at: starts_at,
        ends_at: starts_at + 1.hour
      )

      patch "/api/v1/reservations/#{reservation.id}/cancel"

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.dig("data", "cancelled_at")).to be_present
      expect(reservation.reload.cancelled_at).to be_present
    end

    it "returns validation errors when already cancelled" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 12, min: 0)
      reservation = create(:reservation, :cancelled, starts_at: starts_at, ends_at: starts_at + 1.hour)

      patch "/api/v1/reservations/#{reservation.id}/cancel"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("reservation is already cancelled")
    end

    it "returns validation errors when there are exactly 60 minutes until start time" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 12, min: 0)
      reservation = create(:reservation, starts_at: starts_at, ends_at: starts_at + 1.hour)
      allow(Time).to receive(:current).and_return(starts_at - 60.minutes)

      patch "/api/v1/reservations/#{reservation.id}/cancel"

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("reservation can only be cancelled more than 60 minutes before start time")
    end
  end

  describe "POST /api/v1/reservations" do
    it "creates all daily recurring occurrences" do
      room = create(:room)
      user = create(:user)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Daily standup",
          starts_at: "2026-02-02T10:00:00Z",
          ends_at: "2026-02-02T11:00:00Z",
          recurring: "daily",
          recurring_until: "2026-02-04"
        }
      }

      expect(response).to have_http_status(:created)
      expect(response.parsed_body["data"].size).to eq(3)
      expect(Reservation.count).to eq(3)
    end

    it "requires recurring_until when recurring is present" do
      room = create(:room)
      user = create(:user)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Daily standup",
          starts_at: "2026-02-02T10:00:00Z",
          ends_at: "2026-02-02T11:00:00Z",
          recurring: "daily"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("Recurring until is required when recurring is present")
    end

    it "requires recurring_until to be after the first occurrence" do
      room = create(:room)
      user = create(:user)

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Daily standup",
          starts_at: "2026-02-02T10:00:00Z",
          ends_at: "2026-02-02T11:00:00Z",
          recurring: "daily",
          recurring_until: "2026-02-02"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("Recurring until must be after the first occurrence")
    end

    it "rolls back the whole recurring set if one occurrence conflicts" do
      room = create(:room)
      user = create(:user)
      other_user = create(:user)

      create(
        :reservation,
        room: room,
        user: other_user,
        starts_at: Time.zone.parse("2026-02-04 10:00:00 UTC"),
        ends_at: Time.zone.parse("2026-02-04 11:00:00 UTC")
      )

      post "/api/v1/reservations", params: {
        reservation: {
          room_id: room.id,
          user_id: user.id,
          title: "Daily standup",
          starts_at: "2026-02-02T10:00:00Z",
          ends_at: "2026-02-02T11:00:00Z",
          recurring: "daily",
          recurring_until: "2026-02-04"
        }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.parsed_body.dig("error", "details")).to include("room already has an active reservation for that time")
      expect(Reservation.count).to eq(1)
    end

    it "returns a bad request error when the payload root is missing" do
      post "/api/v1/reservations", params: {}

      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["error"]["message"]).to include("param is missing")
    end
  end
end
