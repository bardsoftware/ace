define( ->

  class Spellchecker
    constructor: (@editor) ->
      @typosUrl = null          # url used to fetch typos
      @suggestionsUrl = null    # url used to fetch corrections for a word
      @typosHash = null         # hash used to check whether the typos list has been changed
      @language = null          # language code, e.g. `en_US`

    _fetchTypos: (hash) =>
      $.getJSON(@typosUrl, null, (typosArray) =>
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
        @typosHash = hash
      )

    # Update spellchecking settings
    # @param {Object} settings: object with the following keys:
    #        @param {String}           alphabet: language's alphabet, used for tokenizing
    #        @param {Boolean}          enabled: whether spellchecking is enabled
    #        @param {String}           language: language code, e.g. `en_US`
    #        @param {Function}         onSettingsUpdateSuccess: success callback
    #        @param {Function(String)} onSettingsUpdateError: error callback, takes error description
    onSettingsUpdated: (settings) =>
      @language = settings.language
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
        @_fetchTypos(session.typosHash)

    # Get corrections list for a word and apply callback to it
    # @param {String} token
    # @param {Function(Array<String>)} callback: function to be applied to resulting corrections list
    getCorrections: (token, callback) =>
      $.getJSON(@suggestionsUrl, {typo: token, language: @language}, callback)


  mySpellchecker = null

  return {
    getInstance: ->
      if mySpellchecker?
        return mySpellchecker
      else
       throw new Error("Spellchecker has not been initialized")

    setup: (editor) ->
      if mySpellchecker?
        throw new Error("Spellchecker has already been initialized")
      else
        mySpellchecker = new Spellchecker(editor)
  }
)
