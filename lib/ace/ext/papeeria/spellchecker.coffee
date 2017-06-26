define( ->

  # @typedef {Function(String, Function(String[]))}         AsyncFetchTypos
  # @typedef {Function(String, String, Function(String[]))} AsyncFetchSuggestions

  makeSet = (array) ->
    set = {}
    for v in array
      set[v] = true
    return set


  class Spellchecker
    constructor: (@editor) ->
      @typosHash = null            # {String} hash used to check whether the typos list has been changed
      @language = null             # {String} language code, e.g. `en_US`
      @asyncFetchTypos = ->        # {AsyncFetchTypos}
      @asyncFetchSuggestions = ->  # {AsyncFetchSuggestions}
      @typos = {}                  # {Map<String, ?>} object whose keys are typos

    _fetchTypos: (hash) =>
      @asyncFetchTypos(@language, (typosArray) =>
        @editor.getSession()._emit("updateSpellcheckingTypos", {typos: typosArray})
        @typos = makeSet(typosArray)
        @typosHash = hash
      )

    # Update spellchecking settings
    # @param {Object} settings: object with the following keys:
    #        @param {String}         punctuation: symbols not considered to be part of a word in given language
    #        @param {Boolean}        isEnabled: whether spellchecking is enabled
    #        @param {String}         tag: language IETF tag with underscore, e.g. `en_US`
    # @param {AsyncFetchTypos}       asyncFetchTypos: will be called in order to fetch typos asynchronously
    # @param {AsyncFetchSuggestions} asyncFetchSuggestions: will be called in order to fetch suggestions async
    onSettingsUpdated: (settings, asyncFetchTypos, asyncFetchSuggestions) =>
      @language = settings.tag
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
      @asyncFetchSuggestions(token, @language, callback)

    # Tell if given word is a typo according to current set of typos
    isWordTypo: (word) => !!@typos[word]


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
