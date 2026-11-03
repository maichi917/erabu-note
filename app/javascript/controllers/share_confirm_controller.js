import { Controller } from "@hotwired/stimulus"

// 初めてシェアするとき、保存の前にニックネームを確認する窓を開く
export default class extends Controller {
  static targets = ["switch", "dialog", "nickname", "rating"]
  static values = { needed: Boolean }

  confirm(event) {
    if (this.confirmed || !this.neededValue || !this.switchTarget.checked) return
    // 星評価がないときはシェアされないので、確認せずにそのまま保存する（保存後にメッセージが出る）
    if (this.ratingTarget.value === "") return

    event.preventDefault()
    this.dialogTarget.showModal()
    this.nicknameTarget.focus()
  }

  share() {
    if (!this.nicknameTarget.reportValidity()) return

    this.confirmed = true
    this.dialogTarget.close()
    this.element.requestSubmit()
  }

  cancel() {
    this.dialogTarget.close()
  }
}
