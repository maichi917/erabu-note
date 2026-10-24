import { Controller } from "@hotwired/stimulus"

const MIN_LENGTH = 2
const DEBOUNCE_MS = 300
const ITEM_CLASS = "cursor-pointer px-3 py-2 text-sm text-slate-700 hover:bg-emerald-50 aria-selected:bg-emerald-100"

// 検索欄に入力すると、アイテム名の候補を表示する
export default class extends Controller {
  static targets = ["input", "list"]
  static values = { url: String }

  disconnect() {
    clearTimeout(this.timer)
  }

  // 入力が止まってから候補を取りに行く（1文字ごとに通信しないため）
  search() {
    clearTimeout(this.timer)

    const query = this.inputTarget.value.trim()
    if (query.length < MIN_LENGTH) {
      this.close()
      return
    }

    this.timer = setTimeout(() => {
      this.listTarget.innerHTML = "<li class=\"px-3 py-2 text-sm text-slate-400\">検索中...</li>"
      this.listTarget.classList.remove("hidden")

      fetch(`${this.urlValue}?q=${encodeURIComponent(query)}`, { headers: { Accept: "application/json" } })
        .then((response) => response.json())
        .then((names) => this.render(names))
        .catch(() => this.close())
    }, DEBOUNCE_MS)
  }

  // ↑↓で候補を選び、Enterで決定、Escで閉じる
  navigate(event) {
    if (this.listTarget.classList.contains("hidden")) return

    const items = Array.from(this.listTarget.querySelectorAll("[role='option']"))
    if (items.length === 0) return

    const activeIndex = items.findIndex((item) => item.getAttribute("aria-selected") === "true")

    if (event.key === "ArrowDown" || event.key === "ArrowUp") {
      event.preventDefault()
      const step = event.key === "ArrowDown" ? 1 : -1
      const nextIndex = (activeIndex + step + items.length) % items.length
      items.forEach((item) => item.setAttribute("aria-selected", "false"))
      items[nextIndex].setAttribute("aria-selected", "true")
      items[nextIndex].scrollIntoView({ block: "nearest" })
    } else if (event.key === "Enter" && activeIndex >= 0) {
      event.preventDefault()
      this.inputTarget.value = items[activeIndex].textContent
      this.close()
    } else if (event.key === "Escape") {
      this.close()
    }
  }

  choose(event) {
    const item = event.target.closest("[role='option']")
    if (!item) return

    this.inputTarget.value = item.textContent
    this.close()
  }

  // 検索欄の外をクリックしたら閉じる
  closeOnOutsideClick(event) {
    if (this.element.contains(event.target)) return

    this.close()
  }

  render(names) {
    if (names.length === 0) {
      this.close()
      return
    }

    this.listTarget.innerHTML = ""
    names.forEach((name) => {
      const item = document.createElement("li")
      item.textContent = name
      item.setAttribute("role", "option")
      item.setAttribute("aria-selected", "false")
      item.className = ITEM_CLASS
      this.listTarget.appendChild(item)
    })
    this.listTarget.classList.remove("hidden")
  }

  close() {
    this.listTarget.innerHTML = ""
    this.listTarget.classList.add("hidden")
  }
}
