import Service from "../service.js"

export default class extends Service {
  logLevel_info
  attrReader_listening

  new() {
    $.intendedState = 'ended'
    $.state = 'ended'
    $.recognizer = null

    _initSpeechRecognizer()
    if ($.recognizer) {
      $.recognizer.onstart = () => _onStart()
      $.recognizer.onend = () => _onEnd()
      $.recognizer.onerror = (e) => _onError(e)
      $.recognizer.onresult = (event) => _onResult(event)
    }
  }

  _initSpeechRecognizer() {
    if ('webkitSpeechRecognition' in window)
      $.recognizer = new webkitSpeechRecognition()
    else if ('SpeechRecognition' in window)
      $.recognizer = new SpeechRecognition()

    if ($.recognizer) {
      $.recognizer.continuous = true
      // Indicate a locale code such as 'fr-FR', 'en-US', to use a particular language for the speech recognition
      $.recognizer.lang = "" // blank uses system's default language
    }
  }

  async start()   { $.intendedState = 'started';  return await _executeStart() }
  restart()       { $.intendedState = 'started';  _executeRestart() }
  end()           { $.intendedState = 'ended';    _executeEnd() }
  get listening()  { $.state == 'started' }
  get ended()      { $.state == 'ended' }


  // Exeuctors

  async _executeStart() {
    if (!$.recognizer) return

    if ($.state != 'started') {
      try {
        $.recognizer.start() // triggers _onStart() callback
      } catch(e) {
        return Promise.resolve(false)
      }

      return new Promise((resolve) => {
        const checkState = () => {
          if ($.state === 'started')
            resolve(true)
          else if ($.state === 'rejected')
            resolve(false)
          else
            runAfter(1, () => checkState())
        }
        checkState()
      })
      // return a promise that loop forever, every 200 ms checking if $.state == 'started' and then the promise resolves when it is

    } else
      _onStart()
  }

  _executeRestart() {
    if (!$.recognizer) return

    if ($.state == 'started')
      _executeEnd() // will eventually trigger _onStart() b/c of intendedState
    else
      _onStart()
  }

  _executeEnd() {
    if (!$.recognizer) return
    $.recognizer.abort()
  }

  _executeIntendedState() {
    if ($.intendedState == 'started') _executeStart()
    if ($.intendedState == 'ended')   _executeEnd()
  }

  // After state change

  _onStart() {
    $.state = 'started' // we may not intend this but we're here
    if ($.intendedState != 'started') _executeIntendedState()
  }

  _onEnd() {
    if ($.state == 'rejected') return

    $.state = 'ended' // we may not intend this but we're here, ensures recognizer will restart
    if ($.intendedState != 'ended') _executeIntendedState()
  }

  _onError(e) {
    if (e.error == 'not-allowed') {
      $.state = 'rejected'
      $.intendedState = 'rejected'
      return
    }

    _executeIntendedState()
  }

  _onResult(event) {
    let transcript = ""
    for (let i = event.resultIndex; i < event.results.length; ++i) {
      if (event.results[i].isFinal) transcript += event.results[i][0].transcript
    }
    transcript = transcript.trim()

    if (transcript.length <= 1) return

    SpeakTo.Transcriber.with.words(transcript)
  }
}
