import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["roomList", "roomTemplate", "usageTemplate", "foodServiceLines", "equipmentServiceLines", "serviceTemplate", "foodTotal", "equipmentTotal", "roomTotal", "proposalTotal"]
  connect() { this.roomIndex = Number(this.element.dataset.nextRoomIndex) || 0; this.serviceIndex = 0; this.usageIndex = 0; this.recalculate() }

  addUsage(event) {
    const room = event.currentTarget.closest("[data-room-entry]")
    const key = `new_${this.usageIndex++}`
    const fragment = this.usageTemplateTarget.content.cloneNode(true)
    fragment.querySelectorAll("*").forEach((element) => {
      for (const attribute of element.attributes) {
        if (attribute.value.includes("USAGE_KEY")) element.setAttribute(attribute.name, attribute.value.replaceAll("USAGE_KEY", key))
        if (attribute.value.includes("ROOM_KEY")) element.setAttribute(attribute.name, attribute.value.replaceAll("ROOM_KEY", room.dataset.bookingKey))
      }
    })
    const date = room.querySelector("[data-room-start]")?.value?.slice(0, 10)
    const dateField = fragment.querySelector("[data-usage-date]")
    if (date && dateField) dateField.value = date
    room.querySelector("[data-usage-list]").append(fragment)
    this.recalculate()
  }

  removeUsage(event) { event.currentTarget.closest("[data-usage-row]")?.remove(); this.recalculate() }

  addRoom() {
    const index = `${this.roomIndex++}`
    const fragment = this.roomTemplateTarget.content.cloneNode(true)
    fragment.querySelectorAll("*").forEach((element) => {
      for (const attribute of element.attributes) if (attribute.value.includes("NEW_ROOM")) element.setAttribute(attribute.name, attribute.value.replaceAll("NEW_ROOM", index))
    })
    this.roomListTarget.append(fragment)
    this.syncRoomOptions()
    this.recalculate()
  }

  removeRoom(event) {
    const entry = event.currentTarget.closest("[data-room-entry]")
    if (!entry) return
    const destroy = entry.querySelector("[data-room-destroy-field]")
    const idField = entry.querySelector("input[name$='[id]']")
    if (destroy && idField) {
      destroy.value = "1"
      entry.querySelectorAll("input, select").forEach((field) => { field.disabled = true })
      destroy.disabled = false
      idField.disabled = false
      entry.hidden = true
    } else entry.remove()
    this.syncRoomOptions()
    this.recalculate()
  }

  addService(event) {
    const picker = event.currentTarget.closest(".tab-pane")?.querySelector("[data-service-picker]")
    const serviceId = picker?.value
    if (!serviceId) return
    const index = `new_${this.serviceIndex++}`
    const fragment = this.serviceTemplateTarget.content.cloneNode(true)
    fragment.querySelectorAll("*").forEach((element) => {
      for (const attribute of element.attributes) if (attribute.value.includes("SERVICE_INDEX")) element.setAttribute(attribute.name, attribute.value.replaceAll("SERVICE_INDEX", index))
    })
    const serviceSelect = fragment.querySelector("[data-service-select]")
    serviceSelect.value = serviceId
    const selected = serviceSelect.selectedOptions[0]
    fragment.querySelector("[data-line-unit]").textContent = this.formatCurrency(Number(selected.dataset.price) || 0)
    const line = fragment.querySelector("[data-service-line]")
    line.dataset.servicePrice = selected.dataset.price
    line.dataset.serviceCategory = selected.dataset.category
    const defaultDate = this.roomListTarget.querySelector("[data-room-entry]:not([hidden]) [data-room-start]")?.value
    const serviceDate = fragment.querySelector("[data-service-date]")
    if (defaultDate && serviceDate) serviceDate.value = defaultDate
    const target = selected.dataset.category === "equipment" ? this.equipmentServiceLinesTarget : this.foodServiceLinesTarget
    target.append(fragment)
    picker.value = ""
    this.syncRoomOptions()
    this.recalculate()
  }

  removeService(event) { event.currentTarget.closest("[data-service-line]")?.remove(); this.recalculate() }

  serviceChanged(event) {
    const line = event.currentTarget.closest("[data-service-line]")
    const option = event.currentTarget.selectedOptions[0]
    line.dataset.servicePrice = option.dataset.price || "0"
    line.dataset.serviceCategory = option.dataset.category || ""
    line.querySelector("[data-line-unit]").textContent = this.formatCurrency(Number(option.dataset.price) || 0)
    const target = option.dataset.category === "equipment" ? this.equipmentServiceLinesTarget : this.foodServiceLinesTarget
    target.append(line)
    this.recalculate()
  }

  syncRoomOptions() {
    const rooms = [...this.roomListTarget.querySelectorAll("[data-room-entry]:not([hidden])")]
    this.element.querySelectorAll("[data-line-booking]").forEach((select) => {
      const current = select.value
      select.replaceChildren()
      rooms.forEach((room) => {
        const option = document.createElement("option")
        option.value = room.dataset.bookingKey
        option.textContent = room.querySelector("[data-room-select]").selectedOptions[0]?.dataset.roomName || "Sala a definir"
        select.append(option)
      })
      select.value = rooms.some((room) => room.dataset.bookingKey === current) ? current : (rooms[0]?.dataset.bookingKey || "")
    })
  }

  recalculate() {
    this.syncRoomOptions()
    let food = 0, equipment = 0, roomTotal = 0
    this.element.querySelectorAll("[data-service-line]").forEach((line) => {
      const option = line.querySelector("[data-service-select]")?.selectedOptions[0]
      const price = Number(option?.dataset.price || line.dataset.servicePrice) || 0
      const category = option?.dataset.category || line.dataset.serviceCategory
      const quantity = Math.max(Number(line.querySelector("[data-line-quantity]")?.value) || 0, 0)
      const subtotal = price * quantity
      line.dataset.servicePrice = price
      line.dataset.serviceCategory = category || ""
      const total = line.querySelector("[data-line-total]")
      if (total) total.textContent = this.formatCurrency(subtotal)
      if (category === "food_beverage") food += subtotal
      if (category === "equipment") equipment += subtotal
    })
    this.roomListTarget.querySelectorAll("[data-room-entry]:not([hidden])").forEach((entry) => {
      const option = entry.querySelector("[data-room-select]")?.selectedOptions[0]
      const type = entry.querySelector("[data-room-rate-type]")?.value || "hourly"
      const rate = Number(option?.dataset[type === "daily" ? "dailyRate" : "hourlyRate"]) || 0
      const duration = new Date(entry.querySelector("[data-room-end]")?.value || "") - new Date(entry.querySelector("[data-room-start]")?.value || "")
      const units = type === "daily" ? this.inclusiveDays(entry.querySelector("[data-room-start]")?.value, entry.querySelector("[data-room-end]")?.value) : this.hourlyUnits(entry, duration)
      const total = rate * units
      roomTotal += total
      const output = entry.querySelector("[data-room-total]")
      if (output) output.textContent = this.formatCurrency(total)
    })
    this.foodTotalTargets.forEach((target) => { target.textContent = this.formatCurrency(food) })
    this.equipmentTotalTargets.forEach((target) => { target.textContent = this.formatCurrency(equipment) })
    this.roomTotalTargets.forEach((target) => { target.textContent = this.formatCurrency(roomTotal) })
    this.proposalTotalTargets.forEach((target) => { target.textContent = this.formatCurrency(food + equipment + roomTotal) })
    this.updateQuote()
  }

  updateQuote() {
    const roomsBody = this.element.querySelector("[data-quote-rooms]")
    const foodServicesBody = this.element.querySelector("[data-quote-services-food]")
    const equipmentServicesBody = this.element.querySelector("[data-quote-services-equipment]")
    if (!roomsBody || !foodServicesBody || !equipmentServicesBody) return
    roomsBody.replaceChildren()
    this.roomListTarget.querySelectorAll("[data-room-entry]:not([hidden])").forEach((entry) => {
      const option = entry.querySelector("[data-room-select]")?.selectedOptions[0]
      const type = entry.querySelector("[data-room-rate-type]")?.value || "hourly"
      const rate = Number(option?.dataset[type === "daily" ? "dailyRate" : "hourlyRate"]) || 0
      const start = entry.querySelector("[data-room-start]")?.value
      const end = entry.querySelector("[data-room-end]")?.value
      const duration = new Date(end || "") - new Date(start || "")
      const units = type === "daily" ? this.inclusiveDays(start, end) : this.hourlyUnits(entry, duration)
      const status = entry.querySelector("select[name$='[status]']")?.selectedOptions[0]?.textContent || "Pendente"
      const formatDateTime = (value) => value ? new Intl.DateTimeFormat("pt-BR").format(new Date(`${value.slice(0, 10)}T00:00:00`)) : "A definir"
      const usageText = [...entry.querySelectorAll("[data-usage-row]")].map((row) => {
        const date = row.querySelector("input[type='date']")?.value
        const from = row.querySelector("input[name$='[start_time]']")?.value
        const to = row.querySelector("input[name$='[end_time]']")?.value
        return date ? `${new Intl.DateTimeFormat("pt-BR").format(new Date(`${date}T00:00:00`))}: ${from || "--:--"}–${to || "--:--"}` : null
      }).filter(Boolean).join(" | ")
      const row = document.createElement("tr")
      ;[option?.dataset.roomName || "A definir", `${formatDateTime(start)} – ${formatDateTime(end)}${usageText ? ` | ${usageText}` : ""}`, status, `${this.formatCurrency(rate)} × ${units} ${type === "daily" ? "diária(s)" : "hora(s)"}`, this.formatCurrency(rate * units)].forEach((value, index) => {
        const cell = document.createElement("td"); cell.textContent = value
        if (index === 4) cell.className = "numeric"
        row.append(cell)
      })
      roomsBody.append(row)
    })
    foodServicesBody.replaceChildren()
    equipmentServicesBody.replaceChildren()
    this.element.querySelectorAll("[data-service-line]").forEach((line) => {
      const option = line.querySelector("[data-service-select]")?.selectedOptions[0]
      if (!option?.value) return
      const qty = Math.max(Number(line.querySelector("[data-line-quantity]")?.value) || 0, 0)
      const price = Number(option.dataset.price) || 0
      const key = line.querySelector("[data-line-booking]")?.value
      const room = [...this.roomListTarget.querySelectorAll("[data-room-entry]")].find((entry) => entry.dataset.bookingKey === key)
      const roomName = room?.querySelector("[data-room-select]")?.selectedOptions[0]?.dataset.roomName || "Sala a definir"
      const serviceDate = line.querySelector("input[type='date']")?.value
      const formattedDate = serviceDate ? new Intl.DateTimeFormat("pt-BR").format(new Date(`${serviceDate}T00:00:00`)) : ""
      const time = line.querySelector("input[type='time']")?.value || "—"
      const row = document.createElement("tr")
      ;[option.textContent, roomName, formattedDate, time, qty, this.formatCurrency(price), this.formatCurrency(price * qty)].forEach((value, index) => {
        const cell = document.createElement("td"); cell.textContent = value
        if (index > 3) cell.className = "numeric"
        row.append(cell)
      })
      const servicesBody = option.dataset.category === "equipment" ? equipmentServicesBody : foodServicesBody
      servicesBody.append(row)
    })
  }

  formatCurrency(amount) { return new Intl.NumberFormat("pt-BR", { style: "currency", currency: "BRL" }).format(amount) }
  inclusiveDays(start, end) {
    if (!start || !end) return 0
    const first = new Date(`${start.slice(0, 10)}T00:00:00`)
    const last = new Date(`${end.slice(0, 10)}T00:00:00`)
    return last >= first ? Math.floor((last - first) / 86400000) + 1 : 0
  }
  hourlyUnits(_entry, duration) {
    return Number.isFinite(duration) && duration > 0 ? Math.ceil(duration / 3600000) : 0
  }
}
