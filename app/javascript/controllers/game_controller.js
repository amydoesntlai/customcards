import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "card", "submitBtn", "counter", "pickCount" ]

  connect() {
    this.selected = new Set()
    this.pickCount = parseInt(this.pickCountTarget?.value || "1")
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

    const form = event.currentTarget
    const ids = [...this.selected]
    const input = form.querySelector("[name='card_ids[]']") ||
                  (() => {
                    // Build hidden inputs dynamically
                    ids.forEach(id => {
                      const inp = document.createElement("input")
                      inp.type  = "hidden"
                      inp.name  = "card_ids[]"
                      inp.value = id
                      form.appendChild(inp)
                    })
                  })()

    if (ids.length !== this.pickCount) return

    this.submitBtnTarget.disabled = true
    this.submitBtnTarget.textContent = "Submitted!"

    fetch(form.action, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content
      },
      body: JSON.stringify({ card_ids: ids })
    }).catch(() => {
      this.submitBtnTarget.disabled = false
      this.submitBtnTarget.textContent = "Submit"
    })
  }

  pickWinner(event) {
    event.preventDefault()
    const form = event.currentTarget
    fetch(form.action, {
      method: "PATCH",
      headers: { "X-CSRF-Token": document.querySelector('meta[name="csrf-token"]').content }
    })
    event.currentTarget.querySelectorAll("button").forEach(b => b.disabled = true)
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
