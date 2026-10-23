import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  page() {
    window.print()
  }

  serviceOrder() {
    document.body.classList.add("printing-service-order")
    window.addEventListener("afterprint", () => {
      document.body.classList.remove("printing-service-order")
    }, { once: true })
    window.print()
  }
}
