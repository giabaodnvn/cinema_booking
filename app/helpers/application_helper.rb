module ApplicationHelper
  include Pagy::Frontend

  # "115" → "1h 55m"
  def format_duration(minutes)
    return "N/A" if minutes.blank? || minutes <= 0
    h = minutes / 60
    m = minutes % 60
    h > 0 ? (m > 0 ? "#{h}h #{m}m" : "#{h}h") : "#{m}m"
  end

  # Coloured age-rating pill
  def age_rating_badge(rating)
    css = case rating
          when "P"   then "bg-green-500/20 text-green-400 border-green-500/40"
          when "T13" then "bg-yellow-500/20 text-yellow-400 border-yellow-500/40"
          when "T16" then "bg-orange-500/20 text-orange-400 border-orange-500/40"
          when "T18" then "bg-red-500/20 text-red-400 border-red-500/40"
          else             "bg-gray-500/20 text-gray-400 border-gray-500/40"
          end
    content_tag(:span, rating.presence || "?",
                class: "inline-flex items-center px-1.5 py-0.5 rounded text-xs font-bold border #{css}")
  end

  # Room type label
  def room_type_label(room_type)
    { "standard" => "Standard", "vip" => "VIP", "imax" => "IMAX", "couple" => "Couple" }
      .fetch(room_type.to_s, room_type.to_s.upcase)
  end

  # Extract YouTube embed URL from watch/share URLs
  def youtube_embed_url(url)
    return nil if url.blank?
    match = url.match(%r{(?:youtube\.com/watch\?v=|youtu\.be/)([a-zA-Z0-9_-]{11})})
    "https://www.youtube.com/embed/#{match[1]}" if match
  end

  # Format price in VND
  def format_price(amount)
    number_to_currency(amount, unit: "₫", separator: ".", delimiter: ",", format: "%n%u", precision: 0)
  end

  # Booking status badge
  def booking_status_badge(status)
    css, label = case status.to_s
                 when "paid"      then ["bg-green-500/20 text-green-400 border-green-500/40", "Đã thanh toán"]
                 when "pending"   then ["bg-yellow-500/20 text-yellow-400 border-yellow-500/40", "Chờ thanh toán"]
                 when "cancelled" then ["bg-red-500/20 text-red-400 border-red-500/40", "Đã huỷ"]
                 else                  ["bg-gray-500/20 text-gray-400 border-gray-500/40", status.to_s.upcase]
                 end
    content_tag(:span, label,
                class: "inline-flex items-center px-2 py-0.5 rounded-full text-xs font-medium border #{css}")
  end

  # Payment method label
  def payment_method_label(method)
    { "cash" => "Tiền mặt", "card" => "Thẻ ngân hàng", "vnpay" => "VNPay", "momo" => "MoMo" }
      .fetch(method.to_s, method.to_s.upcase)
  end

  # Booking type label
  def booking_type_label(type)
    type.to_s == "online" ? "Trực tuyến" : "Tại quầy"
  end

  # Sidebar active state helper for customer nav
  def customer_nav_active?(path)
    current_page?(path) ? "text-white bg-gray-800 font-medium" : "text-gray-400 hover:text-white hover:bg-gray-800"
  end

  # Pagy pagination nav — custom Tailwind-styled HTML
  def pagy_tailwind_nav(pagy, **_opts)
    return "" if pagy.pages <= 1

    html = +'<nav class="flex items-center justify-center gap-1 mt-8" aria-label="Pagination">'

    # Prev
    if pagy.prev
      html << link_to("← Trước", url_for(page: pagy.prev),
                      class: "px-3 py-2 text-sm rounded-lg bg-gray-800 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors")
    else
      html << '<span class="px-3 py-2 text-sm rounded-lg bg-gray-900 text-gray-600 cursor-not-allowed">← Trước</span>'
    end

    # Page numbers
    pagy.series.each do |item|
      if item.is_a?(Integer)
        html << link_to(item, url_for(page: item),
                        class: "px-3 py-2 text-sm rounded-lg bg-gray-800 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors")
      elsif item.is_a?(String) # current page
        html << "<span class=\"px-3 py-2 text-sm rounded-lg bg-red-600 text-white font-semibold\">#{item}</span>"
      else # :gap
        html << '<span class="px-2 py-2 text-sm text-gray-600">…</span>'
      end
    end

    # Next
    if pagy.next
      html << link_to("Sau →", url_for(page: pagy.next),
                      class: "px-3 py-2 text-sm rounded-lg bg-gray-800 text-gray-300 hover:bg-gray-700 hover:text-white transition-colors")
    else
      html << '<span class="px-3 py-2 text-sm rounded-lg bg-gray-900 text-gray-600 cursor-not-allowed">Sau →</span>'
    end

    html << "</nav>"
    html.html_safe
  end
end
