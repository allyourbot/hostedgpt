import Interface from "../interface.js"

// the length of time we pause before reflecting on what was said should
// take into account *what* was said. If the last word was clearly the end
// of a sentence and it ended as a question? e.g. "..., right?" We should
// start considering those words sooner than if the last word is the sound
// of someone's voice trailing off. e.g. "... well..."

// For now, we have a hard-coded silence duration. Maybe we utter a sound
// like "hmm" before this silence duration has elapsed to help it feel more
// responsive? Also, maybe we start processing the response even before
// this duration has elapsed but we delay responding?

export default class extends Interface {
  logLevel_info
  attrReader_covered

  async Flip(turnOn)    { if (turnOn && !$.active) {
                            $.active = true
                            $.covered = false
                            await $.transcriberService.start()
                            await Invoke.Listener()

                          } else if (!turnOn && $.active) {
                            $.active = false
                            await $.transcriberService.end()
                            await Disable.Listener()
                          }
                        }

  async Approve()       { let approved = await $.transcriberService.start()
                          await $.transcriberService.end()
                          return approved
                        }

  log_SpeakTo
  SpeakTo(text)         { if ($.covered) return
                          $.words += text+' '
                          $.silenceService.restartCounter()
                          $.dismissPoller?.end()
                          _shortWaitThenTell()
                        }

  Cover()               { $.covered = true }
  Uncover()             { $.covered = false
                          $.transcriberService.restart()
                          _longWaitThenDismis()
                        }

  attr_words            = ''
  attr_active           = false

  get on()              { return $.active }
  get off()             { return !$.active }

  get supported()       { return Transcriber.$.transcriberService.$.recognizer != null }

  new() {
    $.covered = false
    $.silenceService = new SilenceService
    $.transcriberService = new TranscriberService
  }

  _shortWaitThenTell()  { if (!$.tellPoller?.handler) $.tellPoller = runEvery(0.2, () => {
                            if ($.silenceService.msOfSilence <= 1000) return
                            log('enough silence to start processing...')

                            if (! $.covered) $.covered = true
                            Tell.Listener.to.consider($.words)

                            $.words = ''
                            $.tellPoller.end()
                          })
                        }

  _longWaitThenDismis() { $.silenceService.restartCounter()

                          if (!$.dismissPoller?.handler) $.dismissPoller = runEvery(0.2, () => {
                            if ($.silenceService.msOfSilence <= 30000) return
                            log('enough silence to dismiss...')

                            Dismiss.Listener()
                            $.dismissPoller.end()
                          })
                        }
}
