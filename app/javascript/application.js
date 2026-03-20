// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"
import Swal from "sweetalert2"

// ── Shared dark config ────────────────────────────────────────────────────────
const swalDark = Swal.mixin({
  background: "#111827",
  color: "#f3f4f6",
  confirmButtonColor: "#4f46e5",
  cancelButtonColor: "#374151",
  buttonsStyling: true,
  customClass: {
    popup:         "!rounded-2xl !border !border-gray-700 !shadow-2xl",
    title:         "!text-white !text-lg",
    htmlContainer: "!text-gray-300 !text-sm",
    confirmButton: "!rounded-lg !text-sm !font-semibold !px-5 !py-2.5",
    cancelButton:  "!rounded-lg !text-sm !font-semibold !px-5 !py-2.5",
  },
})

// ── Override Turbo confirm dialogs (fallback for link_to with turbo_confirm) ──
const swalConfirm = (message) => swalDark.fire({
  title: "Xác nhận",
  text: message,
  icon: "warning",
  showCancelButton: true,
  confirmButtonText: "Xác nhận",
  cancelButtonText: "Huỷ",
  reverseButtons: true,
}).then(result => result.isConfirmed)

Turbo.config.confirmMethod = swalConfirm

// ── Flash toast ───────────────────────────────────────────────────────────────
const Toast = Swal.mixin({
  toast: true,
  position: "top-end",
  showConfirmButton: false,
  timer: 4000,
  timerProgressBar: true,
  background: "#1f2937",
  color: "#f3f4f6",
  customClass: {
    popup: "!rounded-xl !border !border-gray-700 !shadow-xl",
  },
  didOpen: (toast) => {
    toast.addEventListener("mouseenter", Swal.stopTimer)
    toast.addEventListener("mouseleave", Swal.resumeTimer)
  },
})

const showFlashToasts = () => {
  const el = document.getElementById("flash-data")
  if (!el) return

  const notice = el.dataset.notice
  const alert  = el.dataset.alert

  // Clear immediately to prevent re-showing on Turbo cache restore
  el.dataset.notice = ""
  el.dataset.alert  = ""

  if (notice) Toast.fire({ icon: "success", title: notice })
  if (alert)  Toast.fire({ icon: "error",   title: alert, timer: 6000 })
}

document.addEventListener("turbo:load", showFlashToasts)
