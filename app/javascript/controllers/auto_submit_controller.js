import { Controller } from "@hotwired/stimulus"

// 選ぶだけでフォームを送信する（絞り込みのプルダウンで使う）
export default class extends Controller {
  submit() {
    this.element.requestSubmit()
  }
}
