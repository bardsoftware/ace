define( ->

  class Spellchecker
    constructor: (@editor, @onError = ->) ->
      @typosUrl = null          # url used to fetch typos
      @suggestionsUrl = null    # url used to fetch corrections for a word
      @typosHash = null         # hash used to check whether the typos list has been changed
      @language = null          # language code, e.g. `en_US`

    _fetchTypos: (hash) =>
      $.getJSON(@typosUrl, null, (typosArray) =>
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
        @typosHash = hash
      ).fail(@onError)

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

    # Update typos hash and refresh list of typos iff hash is different
    # @param {String} typosHash: hash used to check whether the typos list has been changed
    onHashUpdated: (typosHash) =>
      if @typosHash != typosHash
        @_fetchTypos(typosHash)

    # Update spellchecking session
    # @param {String} typosUrl: url used to fetch typos
    # @param {String} suggestionsUrl: url used to fetch corrections for a word
    onSessionUpdated: (typosUrl, suggestionsUrl) =>
      @typosUrl = typosUrl
      @suggestionsUrl = suggestionsUrl
      @_fetchTypos(@typosHash)

    # Get corrections list for a word and apply callback to it
    # @param {String} token
    # @param {Function(Array<String>)} callback: function to be applied to resulting corrections list
    getCorrections: (token, callback) =>
      $.getJSON(@suggestionsUrl, {typo: token, language: @language}, callback).fail(@onError)


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
