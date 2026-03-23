require "rails_helper"

RSpec.describe Reservations::RecurringCreator do
  describe "#call" do
    it "creates all daily occurrences until recurring_until" do
      room = create(:room)
      user = create(:user)

      records = described_class.new(
        room_id: room.id,
        user_id: user.id,
        title: "Daily standup",
        starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0),
        recurring: "daily",
        recurring_until: Date.new(2026, 2, 4)
      ).call

      expect(records.size).to eq(3)
      expect(Reservation.count).to eq(3)
      expect(records.map(&:recurring).uniq).to eq([ "daily" ])
      expect(records.map(&:recurring_until).uniq).to eq([ Date.new(2026, 2, 4) ])
      expect(records.map { |record| record.starts_at.to_date }).to eq(
        [ Date.new(2026, 2, 2), Date.new(2026, 2, 3), Date.new(2026, 2, 4) ]
      )
    end

    it "rolls back all occurrences if one of them is invalid" do
      room = create(:room)
      user = create(:user)

      create(
        :reservation,
        room: room,
        user: user,
        starts_at: Time.zone.local(2026, 2, 4, 10, 0, 0),
        ends_at: Time.zone.local(2026, 2, 4, 11, 0, 0)
      )

      expect do
        described_class.new(
          room_id: room.id,
          user_id: user.id,
          title: "Daily standup",
          starts_at: Time.zone.local(2026, 2, 2, 10, 0, 0),
          ends_at: Time.zone.local(2026, 2, 2, 11, 0, 0),
          recurring: "daily",
          recurring_until: Date.new(2026, 2, 4)
        ).call
      end.to raise_error(ActiveRecord::RecordInvalid)

      expect(Reservation.count).to eq(1)
    end
  end
end
