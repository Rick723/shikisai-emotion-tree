import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "strength", "strengthValue", "afterglow", "afterglowValue", "emotion",
    "tree", "preview", "memo", "dialog", "feltAt", "positionX", "positionY",
    "backButton", "confirmationButton",
    "confirmationEmotion", "confirmationStrength", "confirmationAfterglow",
    "confirmationDate", "confirmationMemo"
  ]

  static values = { today: String }

  connect() {
    this.updateStrength()
    this.updateAfterglow()
  }

  disconnect() {
    this.closeDialog()
  }

  updateStrength() {
    this.strengthValueTarget.value = this.strengthTarget.value
    this.updatePreview()
  }

  updateAfterglow() {
    this.afterglowValueTarget.value = this.afterglowTarget.value
    this.updatePreview()
  }

  selectPosition(event) {
    if (!event.isPrimary || event.button !== 0) return

    const { left, top, width, height } = this.treeTarget.getBoundingClientRect()
    if (width === 0 || height === 0) return

    // Keep coordinates relative to the image, excluding the caption.
    this.position = {
      position_x: Math.min(100, Math.max(0, (event.clientX - left) / width * 100)),
      position_y: Math.min(100, Math.max(0, (event.clientY - top) / height * 100))
    }
    this.positionXTarget.value = this.position.position_x
    this.positionYTarget.value = this.position.position_y
    this.updatePreview()
  }

  updatePreview() {
    const emotion = this.emotionTargets.find(input => input.checked)
    this.previewTarget.hidden = !this.position || !emotion
    this.confirmationButtonTarget.disabled = this.previewTarget.hidden
    if (this.previewTarget.hidden) return

    const style = this.previewTarget.style
    style.setProperty("--preview-x", `${this.position.position_x}%`)
    style.setProperty("--preview-y", `${this.position.position_y}%`)
    style.setProperty("--preview-color", emotion.dataset.emotionColor)
    // Simple monotonic ranges keep even the weakest emotion visible.
    style.setProperty("--preview-radius", `${10 + Number(this.strengthTarget.value) * 0.2}%`)
    style.setProperty("--preview-opacity", 0.2 + Number(this.afterglowTarget.value) * 0.008)
  }

  openConfirmation() {
    const emotion = this.emotionTargets.find(input => input.checked)
    if (!this.position || !emotion || this.dialogTarget.open) return

    this.confirmationEmotionTarget.textContent = emotion.dataset.emotionName
    this.confirmationStrengthTarget.textContent = this.strengthTarget.value
    this.confirmationAfterglowTarget.textContent = this.afterglowTarget.value
    this.confirmationDateTarget.textContent = this.todayValue
    this.confirmationMemoTarget.textContent = this.memoTarget.value || "（なし）"
    this.returnFocusElement = document.activeElement

    this.dialogTarget.showModal()
    this.backButtonTarget.focus()
  }

  back(event) {
    event?.preventDefault()
    this.closeDialog()
  }

  closeDialog() {
    if (this.hasDialogTarget && this.dialogTarget.open) this.dialogTarget.close()
  }

  restoreFocus() {
    if (this.returnFocusElement?.isConnected) this.returnFocusElement.focus({ preventScroll: true })
    this.returnFocusElement = null
  }
}
