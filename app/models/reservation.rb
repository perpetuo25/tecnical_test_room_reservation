class Reservation < ApplicationRecord
  belongs_to :room
  belongs_to :user

  validate :room_capacity_allowed_for_user
  validate :active_future_reservation_limit

  scope :active, -> { where(cancelled_at: nil) }
  scope :future, -> { where("starts_at > ?", Time.current) }

  private

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
end
