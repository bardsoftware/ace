define( ->

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
      $.getJSON(@typosUrl, null, (typosArray) =>
        tmp = {}
        for typo in typosArray
          tmp[typo] = true
        @typos = tmp
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
      )

    # Update spellchecking settings
    # @param {Object} settings: object with the following keys:
    #        @param {String}           alphabet: language's alphabet, used for tokenizing
    #        @param {Boolean}          enabled: whether spellchecking is enabled
    #        @param {String}           language: language code, e.g. `en_US`
    #        @param {Function}         onSettingsUpdateSuccess: success callback
    #        @param {Function(String)} onSettingsUpdateError: error callback, takes error description
    onSettingsUpdated: (settings) =>
      @_init(settings.language)
      @editor.getSession()._emit("changeSpellingCheckSettings", settings)

    # Update spellchecking session
    # @param {Object} session: object with the following keys:
    #        @param {String} typosHash: hash used to check whether the typos list has been changed
    #        @param {String} typosUrl: url used to fetch typos
    #        @param {String} suggestionsUrl: url used to fetch corrections for a word
    onSessionUpdated: (session) =>
      @typosUrl = session.typosUrl
      @suggestionsUrl = session.suggestionsUrl
      if @typosHash != session.typosHash
        @typosHash = session.typosHash
        @_fetchTypos()

    # Check whether token is in JSON incorrect words list.
    # @param {String} token: Token to check.
    # @return {Boolean} False if token is in list, true otherwise.
    check: (token) => token not of @typos

    # Get corrections list for a word (given that the word contains a typo) and apply callback to it
    # @param {String} token: token, supposed to be an actual typo according to the current typos list
    # @param {Function(Array<String>)} callback: function to be applied to resulting corrections list
    getCorrections: (token, callback) =>
      if not @check(token)
        $.getJSON(@suggestionsUrl, {typo: token, language: @language}, callback)


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
