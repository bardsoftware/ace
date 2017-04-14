foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define
define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  Autocomplete = require('ace/autocomplete')
  util = require("ace/autocomplete/util")
  lang = require("../../lib/lang")

  class BiblioFilesCompleter extends Autocomplete.Autocomplete
    constructor: ->
      super()
    setFiles: (files) => @files = files
    _setCompletions: =>
      matches = @files.map((file) -> return {
        name: file.name
        file: file
        meta: file.path
        completer: this
      })
      matches.push({
        name: "Create new file"
        meta: ""
        completer: this
      })
      @completions = new Autocomplete.FilteredList(matches)

    setCreateCallback: (callback) => @createCallback = callback
    setInsertCallback: (callback) => @insertCallback = callback

    _doInsert: (file) =>
      @insertCallback?(file)
      @detach()

    _doCreate: =>
      @createCallback?((=> @editor.completer = null), @_doInsert)

    updateCompletions: (keepPopupPosition) =>
      @_setCompletions()
      prefix = util.getCompletionPrefix(@editor)
      @openPopup(@editor, prefix, keepPopupPosition)

    insertMatch: (editor, data) =>
      if not data?
        data = @popup.getData(@popup.getRow())
      if not data?
        @detach()
        return

      if data.name == "Create new file"
        @_doCreate()
      else
        @_doInsert(data.file)

    detach: =>
      @editor.completer = new Autocomplete.Autocomplete()
      super()


  class BiblioCompleter
    constructor: () ->
      @enabledMendeley = false

    setEnabledMendeley: (enabledMendeley) => @enabledMendeley = enabledMendeley

    getCompletions: (editor, session, pos, prefix, callback) =>
      token = session.getTokenAt(pos.row, pos.column)

      if LatexParsingContext.isType(token, "cite")
        default_result = [{
          name: "Search"
          snippet: "Search " + prefix
          meta: ""
          score: 1000
          meta_score: 10
          completer: this
        }]
        # We don't show Import option to free users
        if @enabledMendeley
          default_result.push({
            name: "Import"
            snippet: "Import " + prefix
            meta: "from Mendeley"
            score: 1000
            meta_score: 10
            completer: this
          })

        callback(null, default_result)
        return

      callback(null, [])
      return

    # Will be called when users choose a Search option
    setSearchCallback: (callback) => @searchCallback = callback
    # Will be called when users choose an Import option
    setImportCallback: (callback) => @importCallback = callback
    insertMatch: (editor, data) =>
      editor.completer.detach()
      editor.completer = null
      if data.name == "Search"
        prefix = util.getCompletionPrefix(editor)
        @searchCallback?({
          query: prefix
          # this callback will be called when user clicks on the search result to insert a bibtex entry
          # so it just opens a passed popup if any and closes an existing one otherwise
          insertCallback: (completer) =>
            completer?.showPopup(editor)
        })
        return
      if data.name == "Import"
        @importCallback?()

  return {
    BiblioCompleter: BiblioCompleter
    BiblioFilesCompleter: BiblioFilesCompleter
  }
)
