class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  BUSINESS_START_HOUR = 9
  BUSINESS_END_HOUR = 18
  MAX_DURATION = 4.hours
  RECURRING_TYPES = %w[daily weekly].freeze

  validates :starts_at, :ends_at, presence: true
  validates :recurring, inclusion: { in: RECURRING_TYPES }, allow_nil: true
  validate :ends_after_starts
  validate :duration_within_limit
  validate :within_business_hours
  validate :room_capacity_allowed_for_user
  validate :active_future_reservation_limit
  validate :no_overlapping_active_reservations
  validate :recurring_until_required
  validate :recurring_until_after_first_occurrence

  scope :active, -> { where(cancelled_at: nil) }
  scope :future, -> { where("starts_at > ?", Time.current) }

  def cancel!
    if cancelled_at.present?
      errors.add(:base, "reservation is already cancelled")
      raise ActiveRecord::RecordInvalid.new(self)
    end

    if starts_at.blank? || starts_at <= 60.minutes.from_now
      errors.add(:base, "reservation can only be cancelled more than 60 minutes before start time")
      raise ActiveRecord::RecordInvalid.new(self)
    end

    update!(cancelled_at: Time.current)
  end

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank? || ends_at > starts_at

    errors.add(:ends_at, "must be after starts_at")
  end

  def duration_within_limit
    return if starts_at.blank? || ends_at.blank? || ends_at <= starts_at
    return if (ends_at - starts_at) <= MAX_DURATION

    errors.add(:ends_at, "cannot exceed 4 hours")
  end

  def within_business_hours
    return if starts_at.blank? || ends_at.blank?

    start_time = starts_at.in_time_zone
    end_time = ends_at.in_time_zone

    unless same_weekday?(start_time, end_time)
      errors.add(:base, "reservations must be on a weekday and within the same day")
      return
    end

    return if within_hour_limits?(start_time, end_time)

    errors.add(:base, "reservations must be between 09:00 and 18:00")
  end

  def room_capacity_allowed_for_user
    return if room.blank? || user.blank? || user.is_admin?
    return if room.capacity.to_i <= user.max_capacity_allowed.to_i

    errors.add(:room, "capacity exceeds the user's limit")
  end

  def active_future_reservation_limit
    return if user.blank? || starts_at.blank? || user.is_admin?

    active_future_count = Reservation.active.future.where(user_id: user_id).where.not(id: id).count
    return if active_future_count < 3

    errors.add(:user, "cannot have more than 3 active future reservations")
  end

  def no_overlapping_active_reservations
    return if room_id.blank? || starts_at.blank? || ends_at.blank?

    overlap = Reservation.active
      .where(room_id: room_id)
      .where.not(id: id)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)

    return unless overlap.exists?

    errors.add(:base, "room already has an active reservation for that time")
  end

  def recurring_until_required
    return if recurring.blank? || recurring_until.present?

    errors.add(:recurring_until, "is required when recurring is present")
  end

  def recurring_until_after_first_occurrence
    return if recurring.blank? || recurring_until.blank? || starts_at.blank?
    return if recurring_until > starts_at.to_date

    errors.add(:recurring_until, "must be after the first occurrence")
  end

  def same_weekday?(start_time, end_time)
    start_time.to_date == end_time.to_date && weekday?(start_time) && weekday?(end_time)
  end

  def within_hour_limits?(start_time, end_time)
    start_minutes = start_time.hour * 60 + start_time.min
    end_minutes = end_time.hour * 60 + end_time.min

    start_minutes >= BUSINESS_START_HOUR * 60 && end_minutes <= BUSINESS_END_HOUR * 60
  end

  def weekday?(time)
    (1..5).cover?(time.wday)
  end
end
