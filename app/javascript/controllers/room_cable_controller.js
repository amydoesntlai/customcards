import { Controller } from "@hotwired/stimulus"
import { createConsumer } from "@hotwired/turbo-rails"

export default class extends Controller {
  static values = { roomCode: String, playerHandId: String }

  connect() {
    this.subscription = createConsumer().subscriptions.create(
      { channel: "GameRoomChannel", room_code: this.roomCodeValue },
      {
        received: (data) => this.handleMessage(data),
        connected: () => this.log("connected"),
        disconnected: () => this.log("disconnected")
      }
    )
  }

  disconnect() {
    this.subscription?.unsubscribe()
  }

  handleMessage(data) {
    switch (data.type) {
      case "presence":
        this.updatePresence(data)
        break
      case "player_joined":
        this.updatePresence(data)
        break
      case "card_submitted":
        this.updateSubmitProgress(data)
        break
      case "round_started":
        if (document.getElementById("lobby-player-count")) {
          Turbo.visit(window.location.href)
        } else {
          this.updateRoundHeader(data)
        }
        break
      case "judging_started":
        // Hand partial is broadcast via Turbo Stream directly to judge
        break
      case "round_complete":
        this.showRoundResult(data)
        break
      case "game_over":
        this.showGameOver(data)
        break
      case "player_count_updated":
        this.updateStartButton(data.count)
        break
      case "system_message":
        this.showBanner(data.message)
        break
    }
  }

  updatePresence(data) {
    const el = document.getElementById("player-status")
    if (!el || !data.players) return
    el.innerHTML = data.players.map(p =>
      `<span class="player-badge ${p.online ? "online" : "offline"}">${p.username} <strong>${p.score}</strong></span>`
    ).join("")

    this.updateStartButton(data.players.length)
  }

  updateStartButton(count) {
    const startBtn = document.querySelector("#start-section button[type='submit']")
    if (startBtn) startBtn.disabled = count < 3
  }

  updateSubmitProgress(data) {
    const el = document.getElementById("submit-progress")
    if (!el) return
    el.textContent = `${data.submitted_count} / ${data.needed_count} submitted`
    if (data.submitted_count >= data.needed_count) {
      el.textContent = "All submitted! Waiting for judge..."
    }
  }

  updateRoundHeader(data) {
    const el = document.getElementById("round-header")
    if (!el) return
    el.innerHTML = `
      <span class="round-number">Round ${data.number}</span>
      <span class="judge-label">Judge: <strong>${data.judge}</strong></span>
    `
  }

  showRoundResult(data) {
    const el = document.getElementById("round-result")
    if (!el) return
    el.innerHTML = `
      <div class="result-banner">
        <strong>${data.winner}</strong> wins with:<br>
        <em>${data.winning_cards.join(" / ")}</em>
      </div>
    `
    el.hidden = false
    setTimeout(() => el.hidden = true, 6000)
  }

  showGameOver(data) {
    const el = document.getElementById("game-over")
    if (!el) return
    const scores = data.final_scores.map(s => `${s.username}: ${s.score}`).join(", ")
    el.innerHTML = `
      <div class="game-over-banner">
        <h2>Game Over!</h2>
        <p><strong>${data.winner}</strong> wins!</p>
        <p class="scores">${scores}</p>
      </div>
    `
    el.hidden = false
  }

  showBanner(message) {
    const el = document.getElementById("system-banner")
    if (!el) return
    el.textContent = message
    el.hidden = false
    setTimeout(() => el.hidden = true, 5000)
  }

  log(event) {
    console.debug(`[GameRoomChannel] ${event}`)
  }
}
