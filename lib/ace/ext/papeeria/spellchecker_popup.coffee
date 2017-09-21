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
    value: action.caption,
    meta: "",
    score: Number.MAX_VALUE,
    action: action.doAction
  }

  mySpellcheckerPopup = null
  mySpellchecker = null


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
    mySpellchecker = Spellchecker.getInstance()
    # Bind SpellcheckerCompleter.showPopup to Alt-Enter editor shortcut.
    command =
      name: "spellcheckerPopup"
      exec: ->
        editor.completer?.detach()
        editor.completer = mySpellcheckerPopup
        editor.completer.showPopup(editor)
      bindKey: "Alt-Enter"
    editor.commands.addCommand(command)


  class SpellcheckerCompleter extends Autocomplete.Autocomplete
    constructor: (@onReplaced, @blacklistAction, @whitelistAction) ->
      super()
      @isDisposable = true
      @typoRange = null
      @typo = null

    # we should hide the popup, if user starts typing
    changeListener: () => @detach()

    gatherCompletions: (editor, callback) =>
      if not mySpellchecker.isEnabled()
        callback(null, {finished: true})
        return true
      # For some reason Autocomplete needs this base object, so
      # I propose just not to touch it.
      session = editor.getSession()
      {row, column} = editor.getCursorPosition()
      @base = session.doc.createAnchor(row, column)
      @typoRange = mySpellchecker.getTypoRange(row, column)
      @typo = session.getTextRange(@typoRange)
      if mySpellchecker.isWordTypo(@typo)
        mySpellchecker.getCorrections(@typo, (correctionsList) =>
          callback(null, {
            prefix: ""
            matches: convertCorrectionList(@whitelistAction, correctionsList)
            finished: true
          })
        )
      else
        callback(null, {
          prefix: ""
          matches: convertCorrectionList(@blacklistAction, [])
          finished: true
        })
      return true

    insertMatch: (data, options) =>
      data ?= @popup.getData(@popup.getRow())
      if data.action
        data.action(@typo)
      else
        replacement = data.value || data
        @editor.getSession().replace(@typoRange, replacement)
        @onReplaced(@typo, replacement)
      @detach()

  return {
    setup: setup
  }
)
