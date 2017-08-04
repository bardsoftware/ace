define((require, exports, module) ->

  Range = require('ace/range').Range

  # @typedef {Function(String, Function(String[]))}         AsyncFetchTypos
  # @typedef {Function(String, String, Function(String[]))} AsyncFetchSuggestions

  makeSet = (array) ->
    set = {}
    for v in array
      set[v] = true
    return set

  NULL_HASH = ""


  class Spellchecker
    constructor: (@editor) ->
      @typosHash = NULL_HASH       # {String} hash used to check whether the typos list has been changed
      @language = null             # {String} language code, e.g. `en_US`
      @asyncFetchTypos = ->        # {AsyncFetchTypos}
      @asyncFetchSuggestions = ->  # {AsyncFetchSuggestions}
      @typos = {}                  # {Map<String, ?>} object whose keys are typos
      @dictionaryCache = new DictionaryCache()

    _fetchTypos: (hash) =>
      @asyncFetchTypos(@language, (typosArray) =>
        @typos = makeSet(typosArray)
        @dictionaryCache.apply(@typos)
        @_sendTyposToAce()
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
      if @language != settings.tag
        # cache is no longer valid if language has changed
        @dictionaryCache.clear()
      @language = settings.tag
      @enabled =  settings.isEnabled
      @splitRe = new RegExp('([^' + settings.punctuation + ']+)', 'g')
      @matchRe = new RegExp('^[^' + settings.punctuation + ']+$')
      @asyncFetchTypos = asyncFetchTypos
      @asyncFetchSuggestions = asyncFetchSuggestions
      @editor.getSession()._emit("changeSpellingCheckSettings", settings)
      @_fetchTypos(NULL_HASH)

    # Update typos hash and refresh list of typos iff hash is different
    # @param {String} typosHash: hash used to check whether the typos list has been changed
    onHashUpdated: (typosHash) =>
      if @typosHash != typosHash
        @_fetchTypos(typosHash)

    # Is spellchecking enabled
    isEnabled: => @enabled

    # Cache given dictionary change so that it appears on screen immediately
    # without waiting for the "get new hash, download new typos" cycle
    # @param word {String}         word being added to dictionary
    # @param toBlacklist {Boolean} whether we should add the word to blacklist (true) or to whitelist (false)
    addWordToDictionaryCache: (word, toBlacklist) =>
      @dictionaryCache.addWord(word, toBlacklist)
      @dictionaryCache.apply(@typos)
      @_sendTyposToAce()

    _sendTyposToAce: => @editor.getSession()._emit("updateSpellcheckingTypos", {typos: @typos})

    # Get corrections list for a word and apply callback to it
    # @param {String} token
    # @param {Function(Array<String>)} callback: function to be applied to resulting corrections list
    getCorrections: (token, callback) =>
      @asyncFetchSuggestions(token, @language, callback)

    # Tell if given word is a typo according to current set of typos
    isWordTypo: (word) => !!@typos[word]

    # Return word range containing given point (according to spellchecker's view of how to tokenize words)
    getTypoRange: (row, column) =>
      session = @editor.getSession()
      matches = session.getLine(row).split(@splitRe)  # includes both tokens and nontokens
      pos = 0
      for w in matches
        pos += w.length
        if (pos > column) or (pos == column and w.match(@matchRe))
          return new Range(row, pos - w.length, row, pos)
      return session.getWordRange(row, column)

    # Check if given range has a typo marker
    hasTypoMarker: (range) =>
      session = @editor.getSession()
      # Optimization: only typos can have typo markers
      if not @isWordTypo(session.getTextRange(range))
        return false
      for k, w of session.getMarkers(true)
        if w.type == "typo" and w.range.isEqual(range)
          return true
      return false


  class DictionaryCache
    constructor: ->
      @storage = {}

    addWord: (word, toBlacklist) => @storage[word] = toBlacklist

    apply: (typos) =>
      for w, v of @storage
        if v then typos[w] = true else delete typos[w]

    clear: => @storage = {}


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
