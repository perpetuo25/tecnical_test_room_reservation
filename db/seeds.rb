# Idempotent seeds for manual API testing.

now = Time.zone.now
next_monday = now.next_occurring(:monday)
next_tuesday = now.next_occurring(:tuesday)
last_friday = now.prev_occurring(:friday)

users = [
  {
    email: "admin@example.com",
    name: "Admin User",
    department: "Operations",
    max_capacity_allowed: 50,
    is_admin: true
  },
  {
    email: "alice@example.com",
    name: "Alice Johnson",
    department: "Engineering",
    max_capacity_allowed: 6,
    is_admin: false
  },
  {
    email: "marcos@example.com",
    name: "Marcos Silva",
    department: "Product",
    max_capacity_allowed: 12,
    is_admin: false
  }
].index_by { |attributes| attributes[:email] }.transform_values do |attributes|
  user = User.find_or_initialize_by(email: attributes[:email])
  user.update!(attributes)
  user
end

rooms = [
  {
    name: "Focus Room",
    capacity: 4,
    has_projector: false,
    has_video_conference: false,
    floor: 1
  },
  {
    name: "Sprint Room",
    capacity: 6,
    has_projector: true,
    has_video_conference: false,
    floor: 2
  },
  {
    name: "Atlas Room",
    capacity: 12,
    has_projector: true,
    has_video_conference: true,
    floor: 3
  },
  {
    name: "Board Room",
    capacity: 20,
    has_projector: true,
    has_video_conference: true,
    floor: 4
  }
].index_by { |attributes| attributes[:name] }.transform_values do |attributes|
  room = Room.find_or_initialize_by(name: attributes[:name])
  room.update!(attributes)
  room
end

reservations = [
  {
    room: rooms.fetch("Sprint Room"),
    user: users.fetch("alice@example.com"),
    title: "Frontend sync",
    starts_at: next_monday.change(hour: 10, min: 0),
    ends_at: next_monday.change(hour: 11, min: 0),
    recurring: nil,
    recurring_until: nil,
    cancelled_at: nil
  },
  {
    room: rooms.fetch("Atlas Room"),
    user: users.fetch("marcos@example.com"),
    title: "Product planning",
    starts_at: next_monday.change(hour: 14, min: 0),
    ends_at: next_monday.change(hour: 16, min: 0),
    recurring: nil,
    recurring_until: nil,
    cancelled_at: nil
  },
  {
    room: rooms.fetch("Board Room"),
    user: users.fetch("admin@example.com"),
    title: "Leadership review",
    starts_at: next_tuesday.change(hour: 11, min: 0),
    ends_at: next_tuesday.change(hour: 12, min: 30),
    recurring: nil,
    recurring_until: nil,
    cancelled_at: nil
  },
  {
    room: rooms.fetch("Focus Room"),
    user: users.fetch("alice@example.com"),
    title: "Cancelled 1:1",
    starts_at: next_tuesday.change(hour: 15, min: 0),
    ends_at: next_tuesday.change(hour: 16, min: 0),
    recurring: nil,
    recurring_until: nil,
    cancelled_at: now
  },
  {
    room: rooms.fetch("Sprint Room"),
    user: users.fetch("marcos@example.com"),
    title: "Retrospective",
    starts_at: last_friday.change(hour: 10, min: 0),
    ends_at: last_friday.change(hour: 11, min: 0),
    recurring: nil,
    recurring_until: nil,
    cancelled_at: nil
  }
]

reservations.each do |attributes|
  reservation = Reservation.find_or_initialize_by(
    room: attributes[:room],
    user: attributes[:user],
    starts_at: attributes[:starts_at]
  )
  reservation.update!(attributes)
end

puts "Seeded #{User.count} users, #{Room.count} rooms, and #{Reservation.count} reservations."
