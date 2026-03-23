module Reservations
  class RecurringCreator
    STEP_BY_RECURRING = {
      "daily" => 1.day,
      "weekly" => 1.week
    }.freeze

    def initialize(attributes)
      @attributes = attributes.to_h.symbolize_keys
    end

    def call
      Reservation.transaction do
        reservations = occurrences.map do |occurrence_attributes|
          reservation = Reservation.new(occurrence_attributes)
          reservation.save!
          reservation
        end

        reservations
      end
    end

    private

    attr_reader :attributes

    def occurrences
      first_reservation = Reservation.new(attributes)
      first_reservation.validate!

      step = STEP_BY_RECURRING.fetch(attributes[:recurring])
      persisted_attributes = attributes.except(:recurring, :recurring_until)
      starts_at = first_reservation.starts_at
      ends_at = first_reservation.ends_at
      recurring_until = first_reservation.recurring_until
      reservations = []

      while starts_at.to_date <= recurring_until
        reservations << persisted_attributes.merge(
          starts_at: starts_at,
          ends_at: ends_at
        )

        starts_at += step
        ends_at += step
      end

      reservations
    end
  end
end
