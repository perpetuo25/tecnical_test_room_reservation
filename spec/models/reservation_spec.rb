require 'rails_helper'

RSpec.describe Reservation, type: :model do
  describe "#cancel!" do
    it "does not allow cancelling an already cancelled reservation" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 12, min: 0)
      reservation = create(:reservation, :cancelled, starts_at: starts_at, ends_at: starts_at + 1.hour)

      expect { reservation.cancel! }
        .to raise_error(ActiveRecord::RecordInvalid)

      expect(reservation.errors[:base]).to include("reservation is already cancelled")
    end

    it "fails exactly 60 minutes before the reservation starts" do
      starts_at = Time.zone.now.next_occurring(:monday).change(hour: 12, min: 0)
      reservation = create(
        :reservation,
        starts_at: starts_at,
        ends_at: starts_at + 1.hour
      )

      allow(Time).to receive(:current).and_return(starts_at - 60.minutes)

      expect { reservation.cancel! }.to raise_error(ActiveRecord::RecordInvalid)

      expect(reservation.errors[:base]).to include("reservation can only be cancelled more than 60 minutes before start time")
    end
  end

  describe "recurring validations" do
    it "requires recurring_until when recurring is present" do
      reservation = build(:reservation, recurring: "daily", recurring_until: nil)

      expect(reservation).not_to be_valid
      expect(reservation.errors[:recurring_until]).to include("is required when recurring is present")
    end

    it "requires recurring_until to be after the first occurrence" do
      starts_at = Time.zone.local(2026, 2, 2, 10, 0, 0)
      reservation = build(
        :reservation,
        recurring: "daily",
        starts_at: starts_at,
        ends_at: starts_at + 1.hour,
        recurring_until: starts_at.to_date
      )

      expect(reservation).not_to be_valid
      expect(reservation.errors[:recurring_until]).to include("must be after the first occurrence")
    end
  end
end
