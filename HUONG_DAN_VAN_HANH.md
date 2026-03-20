# Hướng Dẫn Vận Hành — CinemaBook

> Tài liệu này hướng dẫn vận hành hệ thống đặt vé rạp chiếu phim CinemaBook dành cho Admin, Staff và kỹ thuật viên.

---

## Mục lục

1. [Tổng quan hệ thống](#1-tổng-quan-hệ-thống)
2. [Tài khoản và phân quyền](#2-tài-khoản-và-phân-quyền)
3. [Khởi động hệ thống](#3-khởi-động-hệ-thống)
4. [Hướng dẫn Admin](#4-hướng-dẫn-admin)
5. [Hướng dẫn Staff (Nhân viên quầy)](#5-hướng-dẫn-staff-nhân-viên-quầy)
6. [Quy trình đặt vé của khách hàng](#6-quy-trình-đặt-vé-của-khách-hàng)
7. [Xử lý sự cố thường gặp](#7-xử-lý-sự-cố-thường-gặp)
8. [Backup và bảo trì](#8-backup-và-bảo-trì)

---

## 1. Tổng quan hệ thống

### Kiến trúc

```
Internet ──► Nginx (reverse proxy) ──► Puma (Rails app :3000)
                                              │
                                    ┌─────────┴─────────┐
                                  MySQL              Redis
                                (dữ liệu)       (cache + jobs)
                                                      │
                                                  Sidekiq
                                              (background jobs)
```

### URL mặc định

| Khu vực | URL |
|---------|-----|
| Trang chủ khách hàng | `http://localhost:3002/` |
| Đăng nhập | `http://localhost:3002/users/sign_in` |
| Đăng ký | `http://localhost:3002/users/sign_up` |
| Admin panel | `http://localhost:3002/admin` |
| Staff counter | `http://localhost:3002/staff` |
| Trang cá nhân khách hàng | `http://localhost:3002/customer/profile` |

### Stack công nghệ

- **Framework:** Ruby on Rails 7.2
- **Database:** MySQL (utf8mb4)
- **Cache / Queue:** Redis + Sidekiq
- **Frontend:** Tailwind CSS + Stimulus JS + Turbo
- **Auth:** Devise (email + password)
- **File upload:** Active Storage (local disk)

---

## 2. Tài khoản và phân quyền

### Ba vai trò

| Vai trò | Quyền hạn |
|---------|-----------|
| **customer** | Đăng ký, duyệt phim, đặt vé online, xem lịch sử vé |
| **staff** | Tất cả quyền customer + đặt vé tại quầy, xem danh sách vé tại quầy |
| **admin** | Tất cả quyền staff + quản lý toàn bộ hệ thống (phim, rạp, suất chiếu, người dùng, báo cáo) |

### Tạo tài khoản Admin đầu tiên

Chạy trong Rails console:

```bash
docker compose exec web bin/rails console
# hoặc
bin/rails console
```

```ruby
User.create!(
  name:     "Admin",
  email:    "admin@cinema.com",
  password: "password123",
  role:     :admin
)
```

### Phân quyền tài khoản Staff

1. Đăng nhập với tài khoản Admin
2. Vào **Admin → Người dùng**
3. Tìm tài khoản cần nâng quyền → bấm **Sửa**
4. Chọn role **staff** → **Lưu**

> ⚠️ Khách hàng tự đăng ký sẽ có role **customer** mặc định. Chỉ Admin mới đổi được role.

---

## 3. Khởi động hệ thống

### Với Docker Compose (khuyến nghị)

```bash
# Khởi động toàn bộ stack (web, db, redis)
docker compose up -d

# Kiểm tra trạng thái
docker compose ps

# Xem logs
docker compose logs -f web
```

### Chạy migrations lần đầu

```bash
docker compose exec web bin/rails db:create db:migrate db:seed
```

### Tắt hệ thống

```bash
docker compose down
```

---

## 4. Hướng dẫn Admin

### 4.1 Truy cập Admin Panel

URL: `/admin` — Chỉ tài khoản có role **admin** mới vào được.

Sau khi đăng nhập, hệ thống tự redirect về `/admin`.

### 4.2 Quản lý Phim

**Đường dẫn:** Admin → Phim

#### Thêm phim mới

1. Bấm **＋ Thêm phim**
2. Điền thông tin:
   - **Tiêu đề** *(bắt buộc)*
   - **Mô tả**
   - **Thời lượng** (phút) *(bắt buộc)*
   - **Ngày khởi chiếu**
   - **Trạng thái:** Draft / Sắp chiếu / Đang chiếu / Đã kết thúc
   - **Giới hạn độ tuổi:** P / T13 / T16 / T18
   - **Trailer URL** (link YouTube)
   - **Poster** (upload ảnh)
   - **Thể loại** (chọn nhiều)
3. Bấm **Tạo phim**

#### Trạng thái phim

| Trạng thái | Hiển thị trên web |
|-----------|-------------------|
| Draft | Không hiển thị |
| Sắp chiếu | Hiển thị ở mục "Sắp ra mắt" |
| Đang chiếu | Hiển thị ở trang chủ và danh sách phim |
| Đã kết thúc | Không hiển thị trên trang công khai |

> ⚠️ Không thể xóa phim đang có suất chiếu. Cần hủy/kết thúc các suất chiếu trước.

### 4.3 Quản lý Rạp chiếu và Phòng

**Đường dẫn:** Admin → Rạp chiếu

#### Tạo rạp mới

1. Bấm **＋ Thêm rạp**
2. Điền: Tên rạp, Địa chỉ, Thành phố, SĐT
3. Trạng thái: **Hoạt động** (để hiển thị lên web)

#### Tạo phòng chiếu

1. Vào chi tiết rạp → bấm **＋ Thêm phòng**
2. Điền: Tên phòng, Sức chứa, Loại phòng (Standard/VIP/IMAX/Couple)

#### Tạo ghế ngồi (bắt buộc trước khi tạo suất chiếu)

1. Vào chi tiết rạp → bấm tên phòng → bấm **＋ Tạo ghế**
2. Nhập:
   - **Hàng ghế:** VD `A,B,C,D,E` (cách nhau bằng dấu phẩy)
   - **Số ghế/hàng:** VD `10`
   - **Số bắt đầu:** Thường là `1`
   - **Loại ghế:** Standard / VIP / Couple
3. Bấm **Tạo ghế** → hệ thống tạo hàng loạt tự động

> Ví dụ: Hàng A,B,C × 10 ghế = 30 ghế (A1–A10, B1–B10, C1–C10)

### 4.4 Quản lý Suất chiếu

**Đường dẫn:** Admin → Suất chiếu

#### Tạo suất chiếu

1. Vào Admin → Phim → chọn phim → bấm **＋ Suất chiếu**
2. Điền:
   - **Phòng chiếu:** Chọn từ danh sách
   - **Giờ bắt đầu / kết thúc**
   - **Giá vé** (VND)
3. Hệ thống tự kiểm tra trùng lịch phòng — nếu phòng đã có suất chiếu trong khung giờ đó sẽ báo lỗi.

> ⚠️ Không thể xóa suất chiếu đang có đơn đặt vé. Cần hủy các đơn trước.

### 4.5 Quản lý Người dùng

**Đường dẫn:** Admin → Người dùng

- Xem danh sách tất cả tài khoản
- Xem chi tiết và lịch sử đặt vé của từng người
- **Đổi role:** Bấm **Sửa** → chọn Customer / Staff / Admin

### 4.6 Quản lý Đặt vé

**Đường dẫn:** Admin → Đặt vé

Xem toàn bộ đơn đặt vé với bộ lọc:
- **Tìm kiếm:** Mã vé, tên, email
- **Loại:** Trực tuyến / Tại quầy
- **Trạng thái:** Chờ thanh toán / Đã thanh toán / Đã huỷ
- **Ngày:** Lọc theo ngày tạo

### 4.7 Báo cáo Doanh thu

**Đường dẫn:** Admin → Báo cáo

#### Bộ lọc thời gian

| Preset | Khoảng thời gian |
|--------|-----------------|
| Hôm nay | Ngày hiện tại |
| 7 ngày | 7 ngày gần nhất |
| 30 ngày | 30 ngày gần nhất (mặc định) |
| Tháng này | Từ đầu tháng đến hôm nay |
| Tùy chỉnh | Chọn ngày bắt đầu và kết thúc |

#### Các chỉ số hiển thị

- **Doanh thu** tổng trong kỳ (chỉ tính đơn đã thu tiền)
- **Số đơn đặt vé** đã thanh toán
- **Số vé đã bán**
- **Giá trị trung bình** mỗi đơn
- Biểu đồ doanh thu theo ngày
- Doanh thu theo phim (top 10)
- Doanh thu theo rạp
- Tỷ lệ online vs tại quầy
- Thống kê trạng thái đơn

> 💡 Chỉ các đơn vé có payment status = **completed** mới được tính vào doanh thu.

---

## 5. Hướng dẫn Staff (Nhân viên quầy)

### 5.1 Truy cập Staff Counter

URL: `/staff` — Cần tài khoản có role **staff** hoặc **admin**.

### 5.2 Dashboard Staff

Hiển thị:
- **Vé hôm nay:** Số vé đã bán tại quầy trong ngày
- **Doanh thu (đã thu):** Tổng tiền đã thu trong ngày
- **Danh sách vé gần đây** tại quầy

### 5.3 Quy trình đặt vé tại quầy

**Bước 1 — Tìm suất chiếu** (`/staff/bookings/new`)

1. Bấm **＋ Đặt vé mới**
2. Nhập tên phim hoặc chọn ngày → bấm **Tìm kiếm**
3. Danh sách suất chiếu khớp hiện ra → bấm **Chọn ghế →**

**Bước 2 — Chọn ghế**

1. Sơ đồ ghế hiện ra (màu xám = còn trống, xám mờ = đã đặt, vàng = VIP, hồng = Couple)
2. Bấm vào ghế để chọn (tối đa 8 ghế/lần)
3. Sidebar phải hiện danh sách ghế đã chọn và tổng tiền

**Bước 3 — Điền thông tin khách và thanh toán**

Trong sidebar phải:

- **Email tài khoản** *(tùy chọn)*: Nếu khách có tài khoản, nhập email để gắn với đơn
- **Tên khách** *(bắt buộc nếu không có email)*: Nhập tên khách vãng lai
- **SĐT**: Số điện thoại khách
- **Phương thức thanh toán:** Tiền mặt / Thẻ ngân hàng
- **Thu tiền ngay:** ✅ Tích = đánh dấu đơn đã thanh toán / Bỏ tích = thanh toán sau

4. Bấm **Xác nhận đặt vé**

**Sau khi đặt vé thành công:**
- Hệ thống hiện trang Receipt với mã vé (format: `BKxxxxxxxx`)
- In hoặc đọc mã vé cho khách

### 5.4 Lưu ý quan trọng

- Ghế đã đặt (kể cả đơn online) sẽ hiển thị xám mờ và không thể chọn
- Đơn bị huỷ sẽ giải phóng ghế để đặt lại
- Mỗi lần đặt tối đa **8 ghế**

---

## 6. Quy trình đặt vé của khách hàng

### Bước 1 — Đăng ký / Đăng nhập

- Vào `/users/sign_up` để tạo tài khoản
- Hoặc `/users/sign_in` để đăng nhập

### Bước 2 — Tìm phim

- Trang chủ: Xem phim đang chiếu và sắp ra mắt
- `/movies`: Tìm kiếm theo tên, thể loại, thành phố

### Bước 3 — Chọn suất chiếu

- Vào trang chi tiết phim → Xem danh sách suất chiếu theo ngày và rạp
- Bấm vào giờ chiếu để vào chọn ghế

### Bước 4 — Chọn ghế

- Bấm vào ghế trên sơ đồ
- Xem tổng tiền cập nhật realtime
- Bấm **Đặt vé** khi đã chọn xong

### Bước 5 — Xác nhận

- Hệ thống tạo đơn và redirect về trang xác nhận
- Mã vé hiển thị ngay (format: `BKxxxxxxxx`)
- Khách có thể xem lại tại `/customer/bookings`

### Xem lịch sử đặt vé

- Vào menu Avatar → **Đặt vé của tôi** (`/customer/bookings`)
- Hoặc `/customer/profile` để xem thống kê tổng quan

---

## 7. Xử lý sự cố thường gặp

### Lỗi: "Một hoặc nhiều ghế đã được đặt"

**Nguyên nhân:** Có người khác vừa đặt cùng ghế.

**Xử lý:**
- Khách hàng: Quay lại chọn ghế khác
- Staff: Refresh lại sơ đồ ghế và chọn lại

### Lỗi: "Suất chiếu không còn nhận đặt vé"

**Nguyên nhân:** Suất chiếu đã bắt đầu hoặc bị hủy.

**Xử lý:** Chọn suất chiếu khác.

### Lỗi: Pending migration

```
ActiveRecord::PendingMigrationError
```

**Xử lý:**

```bash
docker compose exec web bin/rails db:migrate
```

### Lỗi: Redis connection refused

**Nguyên nhân:** Redis chưa khởi động.

**Xử lý:**

```bash
docker compose up -d redis
```

### Xem logs lỗi

```bash
# Logs realtime
docker compose logs -f web

# Logs Rails (production)
tail -f log/production.log

# Logs Sidekiq
docker compose logs -f sidekiq
```

### Reset cache

```bash
docker compose exec web bin/rails runner "Rails.cache.clear"
```

---

## 8. Backup và bảo trì

### Backup database

```bash
# Backup
docker compose exec db mysqldump -u root -p cinema_booking_production > backup_$(date +%Y%m%d).sql

# Restore
docker compose exec -T db mysql -u root -p cinema_booking_production < backup_20260319.sql
```

### Chạy migrations an toàn (production)

```bash
# 1. Backup trước
# 2. Chạy migration
docker compose exec web bin/rails db:migrate RAILS_ENV=production

# 3. Kiểm tra
docker compose exec web bin/rails db:migrate:status
```

### Kiểm tra bảo mật định kỳ

```bash
# Quét lỗ hổng bảo mật Rails
docker compose exec web bundle exec brakeman -q

# Kiểm tra gem lỗi thời
docker compose exec web bundle outdated
```

### Cấu hình môi trường production (`.env`)

| Biến | Mô tả | Ví dụ |
|------|-------|-------|
| `DATABASE_URL` | Kết nối MySQL | `mysql2://user:pass@host/db?ssl_mode=required` |
| `REDIS_URL` | Kết nối Redis | `redis://localhost:6379/0` |
| `SECRET_KEY_BASE` | Khóa bí mật Rails | Tạo bằng `bin/rails secret` |
| `RAILS_ENV` | Môi trường | `production` |
| `APP_HOST` | Domain | `cinema.yourdomain.com` |

> ⚠️ **Quan trọng:** Không commit file `.env` vào Git. Thêm vào `.gitignore`.

---

## Phím tắt hữu ích

| Tình huống | URL |
|-----------|-----|
| Trang chủ | `/` |
| Đăng nhập | `/users/sign_in` |
| Đăng ký | `/users/sign_up` |
| Admin dashboard | `/admin` |
| Quản lý phim | `/admin/movies` |
| Quản lý suất chiếu | `/admin/showtimes` |
| Quản lý rạp | `/admin/cinemas` |
| Quản lý đặt vé | `/admin/bookings` |
| Báo cáo doanh thu | `/admin/reports` |
| Staff counter | `/staff` |
| Đặt vé tại quầy | `/staff/bookings/new` |
| Vé của khách hàng | `/customer/bookings` |
| Hồ sơ cá nhân | `/customer/profile` |
| Health check | `/up` |

---

*Tài liệu này được tạo cho phiên bản CinemaBook Rails 7.2. Cập nhật lần cuối: 19/03/2026.*
