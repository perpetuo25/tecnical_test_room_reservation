require "rails_helper"

RSpec.describe Reservation, type: :model do
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
