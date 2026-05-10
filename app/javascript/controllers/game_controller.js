import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "card", "submitBtn", "counter", "pickCount", "submissionCard", "confirmBtn" ]

  connect() {
    this.selected = new Set()
    this.pickCount = this.hasPickCountTarget ? parseInt(this.pickCountTarget.value) : 1
    this.updateUI()
  }

  toggleCard(event) {
    const el = event.currentTarget
    const id = el.dataset.cardId

    if (this.selected.has(id)) {
      this.selected.delete(id)
      el.classList.remove("card--selected")
    } else if (this.selected.size < this.pickCount) {
      this.selected.add(id)
      el.classList.add("card--selected")
    }

    this.updateUI()
  }

  submit(event) {
    event.preventDefault()

    const ids = [...this.selected]
    if (ids.length !== this.pickCount) return

    const form = this.element.querySelector('form')
    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "Submitted!"

    fetch(form.action, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ card_ids: ids })
    }).then(response => {
      if (!response.ok) {
        this.submitBtnTarget.disabled = false
        this.submitBtnTarget.textContent = "Submit"
      }
    }).catch(() => {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = "Submit"
    })
  }

  selectSubmission(event) {
    this.submissionCardTargets.forEach(c => c.classList.remove("submission-card--selected"))
    event.currentTarget.classList.add("submission-card--selected")
    this.selectedUrl = event.currentTarget.dataset.pickUrl
    this.confirmBtnTarget.disabled = false
  }

  pickWinner(event) {
    event.preventDefault()
    if (!this.selectedUrl) return
    this.confirmBtnTarget.disabled = true
    this.submissionCardTargets.forEach(c => c.style.pointerEvents = "none")
    fetch(this.selectedUrl, {
      method: "PATCH",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
  }

  updateUI() {
    const count = this.selected.size
    if (this.hasCounterTarget) {
      this.counterTarget.textContent = `${count} / ${this.pickCount} selected`
    }
    if (this.hasSubmitBtnTarget) {
      this.submitBtnTarget.disabled = count !== this.pickCount
    }
  }
}
