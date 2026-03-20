import { Controller } from "@hotwired/stimulus"

// Manages seat selection UI on the booking page.
//
// Values:
//   price     (Number) — price per seat in VND
//   maxSeats  (Number) — max seats per booking (default 8)
//
// Targets:
//   seat          — each seat <button>
//   selectedDisplay — container showing selected seat badges
//   seatCount       — <span> showing number of selected seats
//   totalPrice      — <span> showing formatted total
//   hiddenInputs    — container where seat_ids[] inputs are injected
//   submitBtn       — the form submit button
//   maxWarning      — warning shown when max seats reached
//   form            — the booking <form>

export default class extends Controller {
  static targets = [
    "seat", "selectedDisplay", "seatCount",
    "totalPrice", "hiddenInputs", "submitBtn", "maxWarning"
  ]
  static values = {
    price:    Number,
    maxSeats: { type: Number, default: 8 }
  }

  connect() {
    // Map<seatId (string) -> seatLabel (string)>
    this.selected = new Map()
    this.#updateUI()
  }

  // Called on each seat button click
  toggle(event) {
    const btn   = event.currentTarget
    if (btn.disabled) return

    const id    = btn.dataset.seatId
    const label = btn.dataset.seatLabel

    if (this.selected.has(id)) {
      this.selected.delete(id)
      this.#styleDeselected(btn)
    } else {
      if (this.selected.size >= this.maxSeatsValue) {
        this.#flashMaxWarning()
        return
      }
      this.selected.set(id, label)
      this.#styleSelected(btn)
    }

    this.#updateUI()
  }

  // ── Private helpers ──────────────────────────────────────────────

  #styleSelected(btn) {
    btn.classList.remove(
      "bg-gray-700", "border-gray-600", "text-gray-300", "hover:bg-gray-600",
      "bg-yellow-900/40", "border-yellow-700/60", "text-yellow-400", "hover:bg-yellow-700/60",
      "bg-pink-900/40", "border-pink-700/60", "text-pink-400", "hover:bg-pink-700/60"
    )
    btn.classList.add("bg-red-600", "border-red-500", "text-white", "scale-110", "shadow-lg", "shadow-red-900/50")
  }

  #styleDeselected(btn) {
    btn.classList.remove("bg-red-600", "border-red-500", "text-white", "scale-110", "shadow-lg", "shadow-red-900/50")

    const type = btn.dataset.seatType
    if (type === "vip") {
      btn.classList.add("bg-yellow-900/40", "border-yellow-700/60", "text-yellow-400", "hover:bg-yellow-700/60")
    } else if (type === "couple") {
      btn.classList.add("bg-pink-900/40", "border-pink-700/60", "text-pink-400", "hover:bg-pink-700/60")
    } else {
      btn.classList.add("bg-gray-700", "border-gray-600", "text-gray-300", "hover:bg-gray-600")
    }
  }

  #updateUI() {
    const count = this.selected.size
    const total = count * this.priceValue

    // Seat count + total price
    this.seatCountTarget.textContent   = count
    this.totalPriceTarget.textContent  = this.#formatVND(total)

    // Selected seats display
    this.selectedDisplayTarget.innerHTML = ""
    if (count === 0) {
      this.selectedDisplayTarget.innerHTML =
        '<span class="text-xs text-gray-600 italic">Chưa chọn ghế nào</span>'
    } else {
      this.selected.forEach((label) => {
        const badge = document.createElement("span")
        badge.textContent = label
        badge.className = "px-2 py-1 text-xs font-bold font-mono bg-red-600/20 border border-red-600/40 text-red-400 rounded"
        this.selectedDisplayTarget.appendChild(badge)
      })
    }

    // Inject hidden inputs for form submission
    this.hiddenInputsTarget.innerHTML = ""
    this.selected.forEach((_label, id) => {
      const input = document.createElement("input")
      input.type  = "hidden"
      input.name  = "seat_ids[]"
      input.value = id
      this.hiddenInputsTarget.appendChild(input)
    })

    // Enable / disable submit button
    this.submitBtnTarget.disabled = count === 0

    // Hide max warning if under limit
    if (count < this.maxSeatsValue) {
      this.maxWarningTarget.classList.add("hidden")
    }
  }

  #flashMaxWarning() {
    this.maxWarningTarget.classList.remove("hidden")
    // Auto-hide after 3s
    clearTimeout(this._warningTimer)
    this._warningTimer = setTimeout(() => {
      this.maxWarningTarget.classList.add("hidden")
    }, 3000)
  }

  #formatVND(amount) {
    return new Intl.NumberFormat("vi-VN").format(amount) + "₫"
  }
}
