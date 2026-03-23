require "rails_helper"

RSpec.describe Reservation, type: :model do
  describe "validations" do
    it "allows a reservation that is exactly 4 hours long" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 9, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 13, 0, 0)
      )

      expect(reservation).to be_valid
    end

    it "allows a reservation ending exactly at 18:00" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 17, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 18, 0, 0)
      )

      expect(reservation).to be_valid
    end

    it "requires end time to be after start time" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 10, 0, 0)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:ends_at]).to include("must be after starts_at")
    end

    it "rejects reservations longer than 4 hours" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 9, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 13, 1, 0)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:ends_at]).to include("cannot exceed 4 hours")
    end

    it "rejects reservations outside business hours" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 8, 59, 0),
        ends_at: Time.zone.local(2026, 2, 2, 10, 0, 0)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:base]).to include("reservations must be between 09:00 and 18:00")
    end

    it "rejects weekend reservations" do
      reservation = build(
        :reservation,
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0).next_occurring(:saturday),
        ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0).next_occurring(:saturday)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:base]).to include("reservations must be on a weekday and within the same day")
    end

    it "rejects overlapping active reservations for the same room" do
      room = create(:room)
      create(
        :reservation,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0)
      )

      reservation = build(
        :reservation,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 10, 30, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 30, 0)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:base]).to include("room already has an active reservation for that time")
    end

    it "allows a reservation starting exactly when another one ends" do
      room = create(:room)
      create(
        :reservation,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0)
      )

      reservation = build(
        :reservation,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 11, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 12, 0, 0)
      )

      expect(reservation).to be_valid
    end

    it "ignores cancelled reservations when checking overlaps" do
      room = create(:room)
      create(
        :reservation,
        :cancelled,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0)
      )

      reservation = build(
        :reservation,
        room: room,
        starts_at: Time.zone.local(2026, 2, 2, 10, 30, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 30, 0)
      )

      expect(reservation).to be_valid
    end
  end

  describe "BR4 room capacity restriction" do
    it "rejects a regular user booking a room above their capacity limit" do
      reservation = build(
        :reservation,
        room: build(:room, capacity: 12),
        user: build(:user, is_admin: false, max_capacity_allowed: 10)
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:room]).to include("capacity exceeds the user's limit")
    end

    it "allows an admin to book any room" do
      reservation = build(
        :reservation,
        room: build(:room, capacity: 20),
        user: build(:user, :admin, max_capacity_allowed: 1)
      )

      expect(reservation).to be_valid
    end
  end

  describe "BR5 active future reservation limit" do
    it "rejects a fourth active future reservation for a regular user" do
      user = create(:user)

      create_list(:reservation, 3, user: user)

      reservation = build(:reservation, user: user)

      expect(reservation).not_to be_valid
      expect(reservation.errors[:user]).to include("cannot have more than 3 active future reservations")
    end

    it "ignores cancelled reservations for the limit" do
      user = create(:user)

      create_list(:reservation, 2, user: user)
      create(:reservation, :cancelled, user: user)

      reservation = build(:reservation, user: user)

      expect(reservation).to be_valid
    end

    it "ignores past reservations for the limit" do
      user = create(:user)

      create_list(
        :reservation,
        3,
        user: user,
        starts_at: 2.days.ago.change(hour: 10),
        ends_at: 2.days.ago.change(hour: 11)
      )

      reservation = build(:reservation, user: user)

      expect(reservation).to be_valid
    end

    it "allows admins to exceed the limit" do
      user = create(:user, :admin)

      create_list(:reservation, 4, user: user)

      reservation = build(:reservation, user: user)

      expect(reservation).to be_valid
    end
  end
end
