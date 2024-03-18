import { Controller } from '@hotwired/stimulus'

// Example:
//
// <div data-controller="transition" data-transition-toggle-class="!hidden">
//   <div id="element-that-shows-and-hides" class="block" data-transition-target="transitionable"></div>
//   <a href="#" data-action="transition#toggleClass">click to toggle</a>
// </div>
//
// Every element that is of target = me will have the class toggled.

export default class extends Controller {
  static classes = [ "toggle" ]
  static targets = [ "transitionable" ]
  static values = {
    afterTimeout: Number
  }

  connect() {
    this.on = false
  }

  transitionableTargetConnected() {
    if (this.afterTimeoutValue) {
      this.transitionableTarget.setAttribute('data-timer', 'true')
      this.transitionableTarget.addEventListener("turbo:before-morph-element", this.boundTransitionableTargetReconnect, { once: true })
      // These two lines above fix a tricky bug. The toast feature uses afterTimeout, however while the timeout is running if the page
      // is refreshed and this refresh *also* includes a toast, this was causing the timer to fail. Without fully understanding why
      // this was occurring, I fixed this by adding a data-timer attribute. By modifying the toast, I can guarantee a morph of this
      // page will morph the toast back to remove this attribute. I then catch the fact that it's about to morph and do a clean
      // disconnect and reconnect.
      this.timeoutHandler = setTimeout(() => this.toggleClass(), this.afterTimeoutValue)
    }
  }

  transitionableTargetDisconnected() {
    if (!this.afterTimeoutValue) return

    if (this.timeoutHandler) {
      clearTimeout(this.timeoutHandler)
      this.timeoutHandler = null
    }
  }

  boundTransitionableTargetReconnect = () => { this.transitionableTargetReconnect() }
  transitionableTargetReconnect() {
    if (this.transitionableTargetDisconnected) this.transitionableTargetDisconnected()
    if (this.transitionableTargetConnected) this.transitionableTargetConnected()
  }

  toggleClass() {
    this.on = !this.on

    this.transitionableTargets.forEach(element => {
      this.toggleClasses.forEach(className => {
        element.classList.toggle(className)
      })
    })

    // Showing and hiding elements can cause the page to flow differently, very similarly to what happens when the
    // browser size changes. Throw this event in case we have other listeners on the resize event.
    window.dispatchEvent(new CustomEvent('main-column-changed'))
  }

  toggleClassOn() {
    if (this.on) return
    this.toggleClass()
  }

  toggleClassOff() {
    if (!this.on) return
    this.toggleClass()
  }
}
