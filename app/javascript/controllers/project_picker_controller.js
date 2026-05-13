import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["select", "newField", "newInput"]

  toggle() {
    const showNew = this.selectTarget.value === "new"
    this.newFieldTarget.hidden = !showNew
    if (showNew) {
      this.newInputTarget.focus()
    } else {
      this.newInputTarget.value = ""
    }
  }
}
