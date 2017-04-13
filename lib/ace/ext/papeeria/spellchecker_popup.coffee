foo = null  # force ace to use ace.define
define((require, exports, module) ->

  ###
  Few types used in this module:

  Correction
    caption: string
    value: string
    meta: string
    score: number
    actionId?: string

  PopupAction
    id: string
    asCorrection(): Correction
    doAction(word: string)

  PopupActionManager
    # Decide which action should respond to given word and return it
    actionForWord(word: string): PopupAction

    # Return action corresponding for given correction if any (or null)
    actionForCorrection(correction: Correction): PopupAction
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
    if action
      list.unshift(action.asCorrection())
    return list

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
  @param {PopupActionManager} actionManager -- autocomplete actions manager
  ###
  setup = (editor, onReplaced, actionManager) ->
    mySpellcheckerPopup = new SpellcheckerCompleter(onReplaced, actionManager)
    # Bind SpellcheckerCompleter.showPopup to Alt-Enter editor shortcut.
    command =
      name: "spellCheckPopup"
      exec: ->
        editor.completer = mySpellcheckerPopup
        editor.completer.showPopup(editor)
      bindKey: "Alt-Enter"
    editor.commands.addCommand(command)


  # Autocomplete class extension since it behaves almost the same way.
  # All we need is to override methods responsible for getting data for
  # popup and inserting chosen correction instead of the current word.
  class SpellcheckerCompleter extends Autocomplete.Autocomplete
    constructor: (@onReplaced, @actionManager) ->
      @isDisposable = true
      super()

    # "Gather" completions extracting current word
    # and take it's corrections list as "completions"
    gatherCompletions: (editor, callback) =>
      # For some reason Autocomplete needs this base object, so
      # I propose just not to touch it.
      session = editor.getSession()
      position = editor.getCursorPosition()
      @base = session.doc.createAnchor(position.row, position.column)
      word = extractWord(editor)
      action = @actionManager.actionForWord(word)
      Spellchecker.getInstance().getCorrections(word, (correctionsList) ->
        callback(null, {
          prefix: ""
          matches: convertCorrectionList(action, correctionsList)
          finished: true
        })
      )
      return true

    # Insert "matching" word instead of the current one.
    # In fact we substitute current word with data,
    # not just insert something.
    insertMatch: (data, options) =>
      data ?= @popup.getData(@popup.getRow())
      action = @actionManager.actionForCorrection(data)
      wordRange = getCurrentWordRange(@editor)
      typo = @editor.getSession().getTextRange(wordRange)
      if action
        action.doAction(typo)
      else
        replacement = data.value || data
        @editor.getSession().replace(wordRange, replacement)
        @onReplaced(typo, replacement)
      @detach()

  return {
    setup: setup
  }
)
