define( ->

  STATE_COMPLETE = 4

  getJson = (url, data, onSuccess) ->
    xhr = new XMLHttpRequest()
    xhr.open("GET", url, true)
    xhr.onreadystatechange = ->
      if xhr.readyState == STATE_COMPLETE and xhr.status == 200
        onSuccess(JSON.parse(xhr.responseText))
    xhr.send(data)


  class Spellchecker
    constructor: (@editor) ->
      @_init(null)

    _init: (language) =>
      @language = language      # language code, e.g. `en_US`
      @typos = {}               # set of typos
      @typosUrl = null          # url used to fetch typos
      @correctionsUrl = null    # url used to fetch corrections for a word
      @typosHash = null         # hash used to check whether the typos list has been changed

    _fetchTypos: =>
      getJson(@typosUrl, null, (typosArray) =>
        tmp = {}
        for typo in typosArray
          tmp[typo] = true
        @typos = tmp
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
      )

    onSettingsUpdated: (language) => @_init(language)

    onSpellcheckingSessionUpdated: ({typosHash, typosUrl, suggestionsUrl}) =>
      @typosUrl = typosUrl
      @suggestionsUrl = suggestionsUrl
      if @typosHash != typosHash
        @typosHash = typosHash
        @_fetchTypos()

    # Check whether token is in JSON incorrect words list.
    # @param {String} token: Token to check.
    # @return {Boolean} False if token is in list, true otherwise.
    check: (token) => token not of @typos

    # TODO: document
    # TODO: fix popup
    getCorrections: (token, callback) =>
      if not @check(token)
        getJson(@suggestionsUrl, {typo: token, language: @language}, callback)


  mySpellchecker = null

  return {
    getInstance: ->
      if mySpellchecker?
        return mySpellchecker
      else
       throw new Error("Spellchecker is not initialized")

    setup: (editor) -> mySpellchecker = new Spellchecker(editor)
  }
)
