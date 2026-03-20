import { Controller } from "@hotwired/stimulus"
import Swal from "sweetalert2"

// Usage (on button_to form):
//   data: { controller: "swal-confirm", action: "submit->swal-confirm#confirm",
//           "swal-confirm-message-value": "Are you sure?" }
export default class extends Controller {
  static values = { message: String }

  confirm(event) {
    event.preventDefault()
    event.stopImmediatePropagation()

    const form = this.element

    Swal.mixin({
      background: "#111827",
      color: "#f3f4f6",
      confirmButtonColor: "#4f46e5",
      cancelButtonColor: "#374151",
      customClass: {
        popup:         "!rounded-2xl !border !border-gray-700 !shadow-2xl",
        title:         "!text-white !text-lg",
        htmlContainer: "!text-gray-300 !text-sm",
        confirmButton: "!rounded-lg !text-sm !font-semibold !px-5 !py-2.5",
        cancelButton:  "!rounded-lg !text-sm !font-semibold !px-5 !py-2.5",
      },
    }).fire({
      title: "Xác nhận",
      text: this.messageValue,
      icon: "warning",
      showCancelButton: true,
      confirmButtonText: "Xác nhận",
      cancelButtonText: "Huỷ",
      reverseButtons: true,
    }).then(result => {
      if (result.isConfirmed) {
        form.removeAttribute("data-action")
        form.requestSubmit()
      }
    })
  }
}
