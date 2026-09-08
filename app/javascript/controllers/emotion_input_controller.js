import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["strength", "strengthValue", "afterglow", "afterglowValue"]

  connect() {
    this.updateStrength()
    this.updateAfterglow()
  }

  updateStrength() {
    this.strengthValueTarget.value = this.strengthTarget.value
  }

  updateAfterglow() {
    this.afterglowValueTarget.value = this.afterglowTarget.value
  }
}
