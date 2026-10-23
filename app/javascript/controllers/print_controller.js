import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  page() {
    window.print()
  }
}
