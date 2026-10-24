import { Controller } from "@hotwired/stimulus"

// 星をクリックして評価を入力する。選択済みの星をもう一度押すと評価をクリアする
export default class extends Controller {
  static targets = ["star", "input"]

  select(event) {
    const value = event.currentTarget.dataset.value
    const nextValue = this.inputTarget.value === value ? "" : value
    this.inputTarget.value = nextValue

    this.starTargets.forEach((star) => {
      const filled = nextValue !== "" && Number(star.dataset.value) <= Number(nextValue)
      star.classList.toggle("text-amber-400", filled)
      star.classList.toggle("text-slate-300", !filled)
      star.classList.toggle("hover:text-amber-300", !filled)
    })
  }
}
