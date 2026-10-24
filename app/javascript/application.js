// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

const AUTOCOMPLETE_MIN_LENGTH = 2
const AUTOCOMPLETE_DEBOUNCE_MS = 300
const AUTOCOMPLETE_ITEM_CLASS =
  "cursor-pointer px-3 py-2 text-sm text-slate-700 hover:bg-emerald-50 aria-selected:bg-emerald-100"
const autocompleteTimers = new WeakMap()

function closeAutocompleteList(list) {
  list.innerHTML = ""
  list.classList.add("hidden")
}

function renderAutocompleteList(list, names) {
  if (names.length === 0) {
    closeAutocompleteList(list)
    return
  }

  list.innerHTML = ""
  names.forEach((name) => {
    const item = document.createElement("li")
    item.textContent = name
    item.setAttribute("role", "option")
    item.setAttribute("aria-selected", "false")
    item.dataset.autocompleteItem = "true"
    item.className = AUTOCOMPLETE_ITEM_CLASS
    list.appendChild(item)
  })

  list.classList.remove("hidden")
}

document.addEventListener("input", (event) => {
  const input = event.target
  if (!input.matches("[data-autocomplete-input]")) return

  const list = input.closest("[data-autocomplete-container]")?.querySelector("[data-autocomplete-list]")
  if (!list) return

  clearTimeout(autocompleteTimers.get(input))

  const query = input.value.trim()
  if (query.length < AUTOCOMPLETE_MIN_LENGTH) {
    closeAutocompleteList(list)
    return
  }

  autocompleteTimers.set(
    input,
    setTimeout(() => {
      list.innerHTML = "<li class=\"px-3 py-2 text-sm text-slate-400\">検索中...</li>"
      list.classList.remove("hidden")

      fetch(`/items/autocomplete?q=${encodeURIComponent(query)}`, { headers: { Accept: "application/json" } })
        .then((response) => response.json())
        .then((names) => renderAutocompleteList(list, names))
        .catch(() => closeAutocompleteList(list))
    }, AUTOCOMPLETE_DEBOUNCE_MS)
  )
})

document.addEventListener("keydown", (event) => {
  if (!event.target.matches("[data-autocomplete-input]")) return

  const list = event.target.closest("[data-autocomplete-container]")?.querySelector("[data-autocomplete-list]")
  if (!list || list.classList.contains("hidden")) return

  const items = Array.from(list.querySelectorAll("[data-autocomplete-item]"))
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
    event.target.value = items[activeIndex].textContent
    closeAutocompleteList(list)
  } else if (event.key === "Escape") {
    closeAutocompleteList(list)
  }
})

document.addEventListener("click", (event) => {
  const selectedItem = event.target.closest("[data-autocomplete-item]")
  if (selectedItem) {
    const list = selectedItem.closest("[data-autocomplete-list]")
    const input = selectedItem.closest("[data-autocomplete-container]")?.querySelector("[data-autocomplete-input]")
    if (input) input.value = selectedItem.textContent
    closeAutocompleteList(list)
    return
  }

  document.querySelectorAll("[data-autocomplete-container]").forEach((container) => {
    if (container.contains(event.target)) return

    const list = container.querySelector("[data-autocomplete-list]")
    if (list) closeAutocompleteList(list)
  })
})
