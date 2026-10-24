import { Controller } from "@hotwired/stimulus"

const ALLOWED_IMAGE_TYPES = ["image/jpeg", "image/png"]
const MAX_IMAGE_SIZE_BYTES = 10 * 1024 * 1024

// 画像を選んだときに、形式・サイズをチェックしてプレビューを表示する
export default class extends Controller {
  static targets = ["preview", "placeholder", "message"]

  select(event) {
    const input = event.currentTarget
    const file = input.files[0]
    if (!file) return

    if (!ALLOWED_IMAGE_TYPES.includes(file.type)) {
      input.value = ""
      this.showMessage("JPEGまたはPNG形式の画像を選択してください", "alert-error")
      return
    }

    if (file.size > MAX_IMAGE_SIZE_BYTES) {
      input.value = ""
      this.showMessage("画像は10MB以下にしてください", "alert-error")
      return
    }

    this.showMessage("画像が選択されました", "alert-success")
    this.previewTarget.src = URL.createObjectURL(file)
    this.previewTarget.classList.remove("hidden")
    this.placeholderTarget.classList.add("hidden")
  }

  showMessage(text, alertClass) {
    this.messageTarget.textContent = text
    this.messageTarget.classList.remove("hidden", "alert-success", "alert-error")
    this.messageTarget.classList.add(alertClass)
  }
}
