import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "code" ]

  redirect(event) {
    event.preventDefault()
    const code = this.codeTarget.value.trim().toUpperCase()
    if (code.length === 6) {
      window.location.href = `/game_rooms/${code}/join`
    }
  }
}
