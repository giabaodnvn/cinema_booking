# Rate limiting with Rack::Attack
# Requires: gem "rack-attack" in Gemfile  +  bundle install
#
# This protects against brute-force, credential stuffing, and API abuse.
# Redis is already in the Gemfile (used by Sidekiq), so the cache store is available.

return unless defined?(Rack::Attack)

# Cache store: defaults to Rails.cache (memory store in dev, Redis in prod via config/environments/production.rb)
# To use Redis explicitly: Rack::Attack.cache.store = ActiveSupport::Cache::RedisCacheStore.new(url: ENV["REDIS_URL"])

# ── Throttle rules ────────────────────────────────────────────────────────────

# 1. Login attempts — 5 per minute per IP
Rack::Attack.throttle("logins/ip", limit: 5, period: 60) do |req|
  req.ip if req.path == "/users/sign_in" && req.post?
end

# 2. Login attempts — 10 per minute per email
Rack::Attack.throttle("logins/email", limit: 10, period: 60) do |req|
  if req.path == "/users/sign_in" && req.post?
    req.params.dig("user", "email").to_s.downcase.strip.presence
  end
end

# 3. Booking creation — 20 per minute per IP (prevents automated bulk booking)
Rack::Attack.throttle("bookings/ip", limit: 20, period: 60) do |req|
  req.ip if req.path.match?(%r{\A/showtimes/\d+/bookings\z}) && req.post?
end

# 4. General API — 300 requests per 5 minutes per IP
Rack::Attack.throttle("api/ip", limit: 300, period: 5.minutes) do |req|
  req.ip unless req.path.start_with?("/assets", "/packs")
end

# ── Block rules ───────────────────────────────────────────────────────────────

# Block IPs that hammer the login endpoint (50+ failures in 10 min → ban 1 hour)
Rack::Attack.blocklist("fail2ban/logins") do |req|
  Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 50, findtime: 10.minutes, bantime: 1.hour) do
    req.path == "/users/sign_in" && req.post?
  end
end

# ── Custom response ───────────────────────────────────────────────────────────

Rack::Attack.throttled_responder = lambda do |env|
  [
    429,
    { "Content-Type" => "text/plain", "Retry-After" => "60" },
    [ "Too many requests. Please slow down." ]
  ]
end
