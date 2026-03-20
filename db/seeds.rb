puts "=" * 60
puts "  Seeding Cinema Booking System"
puts "=" * 60

# ================================================================
# HELPERS
# ================================================================

# Fixed seed anchor — showtimes are relative to this date so that
# re-running seeds on different days produces the SAME start_time
# values, making find_or_create_by! truly idempotent.
SEED_BASE_DATE = Date.new(2026, 3, 20).freeze

# Slot rotation groups per room — 3 movies sharing a room use a
# different group so they never conflict on the same (day, hour).
#
#   Group A: day+1/09h  day+3/14h  day+5/19h
#   Group B: day+1/14h  day+3/19h  day+5/09h
#   Group C: day+1/19h  day+3/09h  day+5/14h
#
# Each (day, hour) pair appears exactly once per group, so up to
# 3 movies in the same room can coexist without any time overlap.
# Slot gaps are 5 h; longest movie is 3 h — no overlap possible.
SLOT_GROUPS = [
  [ [1, 9],  [3, 14], [5, 19] ],
  [ [1, 14], [3, 19], [5, 9]  ],
  [ [1, 19], [3, 9],  [5, 14] ]
].freeze

ROOM_KEYS = %i[standard vip imax].freeze

def create_cinema_with_rooms(name:, address:, city:, phone:)
  cinema = Cinema.find_or_create_by!(name: name, city: city) do |c|
    c.address = address
    c.phone   = phone
    c.status  = :active
  end

  standard = Room.find_or_create_by!(cinema: cinema, name: "Phòng Standard") do |r|
    r.capacity  = 80   # 8 rows × 10 seats
    r.room_type = :standard
  end
  create_seats_for_room(standard, rows: ("A".."H").to_a, seats_per_row: 10, type: :standard)

  vip = Room.find_or_create_by!(cinema: cinema, name: "Phòng VIP") do |r|
    r.capacity  = 32   # 4 rows × 8 seats
    r.room_type = :vip
  end
  create_seats_for_room(vip, rows: ("A".."D").to_a, seats_per_row: 8, type: :vip)

  imax = Room.find_or_create_by!(cinema: cinema, name: "Phòng IMAX") do |r|
    r.capacity  = 72   # 6 rows × 12 seats
    r.room_type = :imax
  end
  create_seats_for_room(imax, rows: ("A".."F").to_a, seats_per_row: 12, type: :standard)

  { cinema: cinema, rooms: { standard: standard, vip: vip, imax: imax } }
end

def create_seats_for_room(room, rows:, seats_per_row:, type:)
  rows.each do |row|
    (1..seats_per_row).each do |num|
      Seat.find_or_create_by!(room: room, row_label: row, seat_number: num) do |s|
        s.seat_type = type
        s.status    = :available
      end
    end
  end
end

def create_showtimes_for_movie(movie, cinema_data, movie_index)
  room_key    = ROOM_KEYS[movie_index % 3]
  group_index = (movie_index / 3) % 3
  slots       = SLOT_GROUPS[group_index]
  room        = cinema_data[:rooms][room_key]

  base_price = movie.now_showing? ? 120_000 : 90_000
  price = case room.room_type
          when "vip"  then base_price * 1.5
          when "imax" then base_price * 1.8
          else             base_price
          end

  slots.map do |day_offset, hour|
    start_time = SEED_BASE_DATE.advance(days: day_offset).to_time + hour.hours
    end_time   = start_time + movie.duration.minutes

    Showtime.find_or_create_by!(movie: movie, room: room, start_time: start_time) do |s|
      s.end_time = end_time
      s.price    = price.to_f
      s.status   = :scheduled
    end
  end
end

def create_sample_booking(user:, showtime:, seat_count:, booking_type:, created_by: nil)
  return if Booking.exists?(user: user, showtime: showtime)

  seats = showtime.room.seats.available.limit(seat_count).to_a
  return unless seats.size == seat_count

  total = showtime.price * seat_count

  booking = Booking.create!(
    user:         user,
    showtime:     showtime,
    total_amount: total,
    booking_type: booking_type,
    status:       :paid,
    created_by:   created_by
  )

  seats.each do |seat|
    BookingSeat.create!(
      booking:  booking,
      seat:     seat,
      showtime: showtime,
      price:    showtime.price
    )
  end

  Payment.create!(
    booking:          booking,
    method:           %i[cash card vnpay momo].sample,
    amount:           total,
    status:           :completed,
    paid_at:          Time.current - rand(1..48).hours,
    transaction_code: "TXN#{SecureRandom.alphanumeric(10).upcase}"
  )

  booking
end

# ================================================================
# 1. USERS
# ================================================================
puts "\n[1/6] Creating users..."

admin = User.find_or_create_by!(email: "admin@cinema.com") do |u|
  u.name     = "Nguyễn Quản Trị"
  u.phone    = "0901000001"
  u.password = "password123"
  u.role     = :admin
end

staff = User.find_or_create_by!(email: "staff@cinema.com") do |u|
  u.name     = "Trần Nhân Viên"
  u.phone    = "0901000002"
  u.password = "password123"
  u.role     = :staff
end

customer_names = [
  "Nguyễn Thị Lan",
  "Phạm Văn Hùng",
  "Lê Thị Hoa",
  "Trần Minh Tuấn",
  "Võ Thị Ngọc"
]

customers = (1..5).map do |i|
  User.find_or_create_by!(email: "customer#{i}@cinema.com") do |u|
    u.name     = customer_names[i - 1]
    u.phone    = "090200000#{i}"
    u.password = "password123"
    u.role     = :customer
  end
end

puts "   Users: #{User.count}"

# ================================================================
# 2. GENRES
# ================================================================
puts "[2/6] Creating genres..."

genre_names = %w[Action Drama Comedy Horror Animation]
genres      = genre_names.map { |name| Genre.find_or_create_by!(name: name) }
genre_map   = genres.index_by(&:name)

puts "   Genres: #{Genre.count}"

# ================================================================
# 3. MOVIES
# ================================================================
puts "[3/6] Creating movies..."

movies_data = [
  # ---- now_showing (index 0–4) → standard / vip / imax / standard / vip
  {
    title:        "Lớp Trưởng Phải Yêu Anh",
    description:  "Câu chuyện tình yêu hài hước giữa lớp trưởng nghiêm túc và chàng trai bất cần.",
    duration:     115,
    release_date: Date.current - 14.days,
    status:       :now_showing,
    age_rating:   "T13",
    genres:       %w[Comedy Drama]
  },
  {
    title:        "Người Nhện: Vũ Trụ Không Gian",
    description:  "Peter Parker đối mặt với kẻ thù nguy hiểm nhất đến từ vũ trụ song song.",
    duration:     148,
    release_date: Date.current - 7.days,
    status:       :now_showing,
    age_rating:   "T13",
    genres:       %w[Action]
  },
  {
    title:        "Quỷ Nhập Tràng: Hồi Sinh",
    description:  "Một nghi lễ bí ẩn khơi dậy thực thể cổ xưa đang ngủ yên dưới ngôi làng.",
    duration:     105,
    release_date: Date.current - 10.days,
    status:       :now_showing,
    age_rating:   "T16",
    genres:       %w[Horror]
  },
  {
    title:        "Avengers: Kỷ Nguyên Mới",
    description:  "Các siêu anh hùng hợp sức lần cuối ngăn chặn thảm họa diệt vong toàn vũ trụ.",
    duration:     180,
    release_date: Date.current - 3.days,
    status:       :now_showing,
    age_rating:   "T13",
    genres:       %w[Action Drama]
  },
  {
    title:        "Mai",
    description:  "Hành trình tìm lại chính mình của người phụ nữ mạnh mẽ giữa những biến cố cuộc đời.",
    duration:     128,
    release_date: Date.current - 21.days,
    status:       :now_showing,
    age_rating:   "T18",
    genres:       %w[Drama]
  },
  # ---- upcoming (index 5–7) → imax / standard / vip
  {
    title:        "Doraemon: Nobita Và Hành Tinh Thú Cưng",
    description:  "Nobita khám phá hành tinh bí ẩn nơi muôn loài thú cưng đang chờ giải cứu.",
    duration:     95,
    release_date: Date.current + 14.days,
    status:       :upcoming,
    age_rating:   "P",
    genres:       %w[Animation Comedy]
  },
  {
    title:        "Kong: Vương Triều Huyền Bí",
    description:  "Kong quay trở lại với sức mạnh chưa từng có bảo vệ vương quốc tổ tiên.",
    duration:     130,
    release_date: Date.current + 21.days,
    status:       :upcoming,
    age_rating:   "T13",
    genres:       %w[Action]
  },
  {
    title:        "Cậu Bé Mất Tích",
    description:  "Hành trình đầy cảm xúc của cậu bé tìm đường về gia đình qua thế giới kỳ diệu.",
    duration:     110,
    release_date: Date.current + 30.days,
    status:       :upcoming,
    age_rating:   "P",
    genres:       %w[Animation Drama]
  }
]

movies = movies_data.map.with_index do |data, _idx|
  movie = Movie.find_or_create_by!(title: data[:title]) do |m|
    m.description  = data[:description]
    m.duration     = data[:duration]
    m.release_date = data[:release_date]
    m.status       = data[:status]
    m.age_rating   = data[:age_rating]
  end

  data[:genres].each do |name|
    MovieGenre.find_or_create_by!(movie: movie, genre: genre_map[name])
  end

  movie
end

puts "   Movies: #{Movie.count}"

# ================================================================
# 4. CINEMAS + ROOMS + SEATS
# ================================================================
puts "[4/6] Creating cinemas, rooms and seats..."

hanoi_data = create_cinema_with_rooms(
  name:    "CGV Vincom Bà Triệu",
  address: "191 Bà Triệu, Hai Bà Trưng",
  city:    "Hà Nội",
  phone:   "024 3974 3333"
)

hcm_data = create_cinema_with_rooms(
  name:    "CGV Crescent Mall",
  address: "101 Tôn Dật Tiên, Quận 7",
  city:    "TP.HCM",
  phone:   "028 5413 6666"
)

cinema_data_list = [ hanoi_data, hcm_data ]

puts "   Cinemas: #{Cinema.count}"
puts "   Rooms:   #{Room.count}"
puts "   Seats:   #{Seat.count}"

# ================================================================
# 5. SHOWTIMES
# ================================================================
puts "[5/6] Creating showtimes..."

all_showtimes = []
cinema_data_list.each do |cinema_data|
  movies.each_with_index do |movie, idx|
    all_showtimes.concat(create_showtimes_for_movie(movie, cinema_data, idx))
  end
end

puts "   Showtimes: #{Showtime.count}"

# ================================================================
# 6. SAMPLE BOOKINGS + PAYMENTS
# ================================================================
puts "[6/6] Creating sample bookings..."

[
  { user: customers[0], showtime: all_showtimes[0],  seats: 2, type: :online              },
  { user: customers[1], showtime: all_showtimes[3],  seats: 3, type: :online              },
  { user: customers[2], showtime: all_showtimes[6],  seats: 2, type: :offline, by: staff  },
  { user: customers[3], showtime: all_showtimes[9],  seats: 1, type: :online              },
  { user: customers[4], showtime: all_showtimes[12], seats: 2, type: :offline, by: staff  }
].each do |t|
  create_sample_booking(
    user:         t[:user],
    showtime:     t[:showtime],
    seat_count:   t[:seats],
    booking_type: t[:type],
    created_by:   t[:by]
  )
end

puts "   Bookings: #{Booking.count}"
puts "   Payments: #{Payment.count}"

# ================================================================
# SUMMARY
# ================================================================
puts "\n" + "=" * 60
puts "  DATABASE SUMMARY"
puts "=" * 60
printf "  %-16s %4d  (admin: %d, staff: %d, customer: %d)\n",
       "Users",       User.count, User.admin.count, User.staff.count, User.customer.count
printf "  %-16s %4d\n", "Genres",        Genre.count
printf "  %-16s %4d  (now_showing: %d, upcoming: %d)\n",
       "Movies",      Movie.count, Movie.now_showing.count, Movie.upcoming.count
printf "  %-16s %4d\n", "Cinemas",       Cinema.count
printf "  %-16s %4d  (standard: %d, vip: %d, imax: %d)\n",
       "Rooms",        Room.count, Room.standard.count, Room.vip.count, Room.imax.count
printf "  %-16s %4d\n", "Seats",         Seat.count
printf "  %-16s %4d  (scheduled: %d)\n",
       "Showtimes",    Showtime.count, Showtime.scheduled.count
printf "  %-16s %4d  (paid: %d)\n",
       "Bookings",     Booking.count, Booking.paid.count
printf "  %-16s %4d\n", "Booking Seats", BookingSeat.count
printf "  %-16s %4d  (completed: %d)\n",
       "Payments",     Payment.count, Payment.completed.count
puts "=" * 60

puts "\n  TEST CREDENTIALS"
puts "  " + "-" * 46
puts "  ADMIN    admin@cinema.com        / password123"
puts "  STAFF    staff@cinema.com        / password123"
(1..5).each { |i| puts "  CUST #{i}   customer#{i}@cinema.com   / password123" }
puts "=" * 60
