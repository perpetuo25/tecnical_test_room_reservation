class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  BUSINESS_HOURS_START = 9
  BUSINESS_HOURS_END = 18
  MAX_DURATION = 4.hours

  validates :starts_at, :ends_at, presence: true
  validate :ends_after_starts
  validate :duration_within_limit
  validate :within_business_hours
  validate :no_overlapping_active_reservations
  validate :room_capacity_allowed_for_user
  validate :active_future_reservation_limit

  scope :active, -> { where(cancelled_at: nil) }
  scope :future, -> { where("starts_at > ?", Time.current) }

  private

  def ends_after_starts
    return if starts_at.blank? || ends_at.blank?
    return if ends_at > starts_at

    errors.add(:ends_at, "must be after starts_at")
  end

  def duration_within_limit
    return if starts_at.blank? || ends_at.blank?
    return unless ends_at > starts_at
    return if (ends_at - starts_at) <= MAX_DURATION

    errors.add(:ends_at, "cannot exceed 4 hours")
  end

  def within_business_hours
    return if starts_at.blank? || ends_at.blank?

    start_time = starts_at.in_time_zone
    end_time = ends_at.in_time_zone

    unless weekday?(start_time) && weekday?(end_time) && start_time.to_date == end_time.to_date
      errors.add(:base, "reservations must be on a weekday and within the same day")
      return
    end

    return if within_hour_limits?(start_time, end_time)

    errors.add(:base, "reservations must be between 09:00 and 18:00")
  end

  def no_overlapping_active_reservations
    return if starts_at.blank? || ends_at.blank? || room_id.blank?

    overlapping = Reservation
      .where(room_id: room_id, cancelled_at: nil)
      .where.not(id: id)
      .where("starts_at < ? AND ends_at > ?", ends_at, starts_at)

    return unless overlapping.exists?

    errors.add(:base, "room already has an active reservation for that time")
  end

  def room_capacity_allowed_for_user
    return if room.blank? || user.blank?
    return if user.is_admin?
    return if room.capacity.to_i <= user.max_capacity_allowed.to_i

    errors.add(:room, "capacity exceeds the user's limit")
  end

  def active_future_reservation_limit
    return if user.blank? || starts_at.blank?
    return if user.is_admin?

    active_future_count = Reservation
      .where(user_id: user_id, cancelled_at: nil)
      .where("starts_at > ?", Time.current)
      .where.not(id: id)
      .count

    return if active_future_count < 3

    errors.add(:user, "cannot have more than 3 active future reservations")
  end

  def weekday?(time)
    time.monday? || time.tuesday? || time.wednesday? || time.thursday? || time.friday?
  end

  def within_hour_limits?(start_time, end_time)
    start_minutes = start_time.hour * 60 + start_time.min
    end_minutes = end_time.hour * 60 + end_time.min

    start_minutes >= BUSINESS_HOURS_START * 60 && end_minutes <= BUSINESS_HOURS_END * 60
  end
end
