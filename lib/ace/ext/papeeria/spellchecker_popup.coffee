foo = null  # force ace to use ace.define
define((require, exports, module) ->

  ###
  Few types used in this module:

  Correction
    caption: string
    value: string
    meta: string
    score: number
    action?(word: string)

  PopupAction
    caption: string
    doAction(word: string)
  ###

  Autocomplete = require('ace/autocomplete')
  Spellchecker = require('ace/ext/papeeria/spellchecker')

  ###
  Returns Range object that describes the current word position.
  @param {Editor} editor: editor object.
  @return {Range}: current word range.
  ###
  getCurrentWordRange = (editor) ->
    session = editor.getSession()
    row = editor.getCursorPosition().row
    col = editor.getCursorPosition().column
    return session.getWordRange(row, col)

  ###
  Convert an array of string to popup-eligible structure.
  @param {PopupAction} action -- action object to be prepended to the resulting list (or null)
  @param {Array<String>} corrections -- array of corrections
  @return {Array<Correction>}
  ###
  convertCorrectionList = (action, corrections) ->
    list = ({caption: item, value: item, meta: "", score: corrections.length - i} for item, i in corrections)
    list.unshift(actionAsCorrection(action))
    return list

  # PopupAction to Correction converter
  actionAsCorrection = (action) -> {
    caption: action.caption,
    value: "",
    meta: "",
    score: Number.MAX_VALUE,
    action: action.doAction
  }

  ###
  Get the word under the cursor.
  @param {Editor} editor: editor object.
  @return {String}: the current word.
  ###
  extractWord = (editor) ->
    session = editor.getSession()
    wordRange = getCurrentWordRange(editor)
    return session.getTextRange(wordRange)

  mySpellcheckerPopup = null


  ###
  Sets up spellchecker popup and implements some routines
  to work on current in the editor.
  @param {Editor} editor -- ace editor
  @param {(String, String) -> void} onReplaced -- callback taking typo and replacement
  @param {PopupAction} blacklistAction -- action to be applied if popup target is not a typo
  @param {PopupAction} whitelistAction -- action to be applied if popup target is a typo
  ###
  setup = (editor, onReplaced, blacklistAction, whitelistAction) ->
    mySpellcheckerPopup = new SpellcheckerCompleter(onReplaced, blacklistAction, whitelistAction)
    # Bind SpellcheckerCompleter.showPopup to Alt-Enter editor shortcut.
    command =
      name: "spellCheckPopup"
      exec: ->
        editor.completer = mySpellcheckerPopup
        editor.completer.showPopup(editor)
      bindKey: "Alt-Enter"
    editor.commands.addCommand(command)


  class SpellcheckerCompleter extends Autocomplete.Autocomplete
    constructor: (@onReplaced, @blacklistAction, @whitelistAction) ->
      @isDisposable = true
      super()

    # we should hide the popup, if user starts typing
    changeListener: () => @detach()

    gatherCompletions: (editor, callback) =>
      # For some reason Autocomplete needs this base object, so
      # I propose just not to touch it.
      session = editor.getSession()
      position = editor.getCursorPosition()
      @base = session.doc.createAnchor(position.row, position.column)
      word = extractWord(editor)
      action = @_chooseAction(word)
      Spellchecker.getInstance().getCorrections(word, (correctionsList) ->
        callback(null, {
          prefix: ""
          matches: convertCorrectionList(action, correctionsList)
          finished: true
        })
      )
      return true

    _chooseAction: (word) =>
      if Spellchecker.getInstance().isWordTypo(word)
        return @whitelistAction
      return @blacklistAction

    insertMatch: (data, options) =>
      data ?= @popup.getData(@popup.getRow())
      wordRange = getCurrentWordRange(@editor)
      typo = @editor.getSession().getTextRange(wordRange)
      if data.action
        data.action(typo)
      else
        replacement = data.value || data
        @editor.getSession().replace(wordRange, replacement)
        @onReplaced(typo, replacement)
      @detach()

  return {
    setup: setup
  }
)
