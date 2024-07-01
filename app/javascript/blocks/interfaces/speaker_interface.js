import Interface from "../interface.js"

export default class extends Interface {
  logLevel_info

  log_Prompt
  Prompt(words)             { $.audioService.speakNext(words) }
  Reset()                   { $.audioService.stop() }
  async Play(sound, onEnd)  { await $.audioService.play(sound, onEnd) }
  Loop(sec, sound)          { $.audioService.playEvery(sec, sound) }

  get speaking()            { $.audioService.speaking }
  get busy()                { $.audioService.busy }

  new() {
    $.audioService = new AudioService
    $.audioService.onBusyChanged = (busy) => {
      console.log(`onbusyChanged(${busy})`)
      if (!busy) {
        Play.Speaker.sound('pop', () => {
          Loop.Speaker.every(8, 'typing1')
        })
        Uncover.Transcriber()
      }
    }
  }
}
