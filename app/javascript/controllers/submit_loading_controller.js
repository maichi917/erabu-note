import { Controller } from "@hotwired/stimulus"

// 送信中のメッセージを表示し、送信ボタンを押せなくする（二重送信を防ぐ）
export default class extends Controller {
  static targets = ["message", "button"]

  show() {
    this.messageTarget.classList.remove("hidden")
    this.buttonTargets.forEach((button) => { button.disabled = true })
  }
}
