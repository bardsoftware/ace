define( ->

  # @typedef {Function(String, String, Function(String[]))}         AsyncFetchTypos
  # @typedef {Function(String, String, String, Function(String[]))} AsyncFetchSuggestions

  class Spellchecker
    constructor: (@editor) ->
      @typosHash = null            # {String} hash used to check whether the typos list has been changed
      @language = null             # {String} language code, e.g. `en_US`
      @engine = null               # {String} spellchecking engine(Hunspell or Grazie)
      @asyncFetchTypos = ->        # {AsyncFetchTypos}
      @asyncFetchSuggestions = ->  # {AsyncFetchSuggestions}

    _fetchTypos: (hash) =>
      @asyncFetchTypos(@language, @engine, (typosArray) =>
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
        @typosHash = hash
      )

    # Update spellchecking settings
    # @param {Object} settings: object with the following keys:
    #        @param {String}         alphabet: language's alphabet, used for tokenizing
    #        @param {Boolean}        isEnabled: whether spellchecking is enabled
    #        @param {String}         tag: language IETF tag with underscore, e.g. `en_US`
    #        @param {String}         engine: spellchecker engine tag (e.g. Hunspell or Grazie)
    # @param {AsyncFetchTypos}       asyncFetchTypos: will be called in order to fetch typos asynchronously
    # @param {AsyncFetchSuggestions} asyncFetchSuggestions: will be called in order to fetch suggestions async
    onSettingsUpdated: (settings, asyncFetchTypos, asyncFetchSuggestions) =>
      @language = settings.tag
      @engine = settings.engine
      @asyncFetchTypos = asyncFetchTypos
      @asyncFetchSuggestions = asyncFetchSuggestions
      @editor.getSession()._emit("changeSpellingCheckSettings", settings)
      @_fetchTypos(null)

    # Update typos hash and refresh list of typos iff hash is different
    # @param {String} typosHash: hash used to check whether the typos list has been changed
    onHashUpdated: (typosHash) =>
      if @typosHash != typosHash
        @_fetchTypos(typosHash)

    # Get corrections list for a word and apply callback to it
    # @param {String} token
    # @param {Function(Array<String>)} callback: function to be applied to resulting corrections list
    getCorrections: (token, callback) =>
      @asyncFetchSuggestions(token, @language, @engine, callback)


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
