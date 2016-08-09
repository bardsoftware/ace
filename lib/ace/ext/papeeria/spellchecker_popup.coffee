define( ['ace/autocomplete'], (Autocomplete) ->
  # Returns Range object that describes the current word position.
  # @param {Editor} editor: editor object.
  # @return {Range}: current word range.
  getCurrentWordRange = (editor) ->
    session = editor.getSession()
    row = editor.getCursorPosition().row
    col = editor.getCursorPosition().column
    return session.getWordRange(row, col)

  # Convert an array of string to popup-eligible structure.
  # @param {Array} corrections: array of strings with substitution options.
  # @return {Array}: array of JSONs, actually.
  convertCorrectionList = (corrections) ->
    return ({caption: item, value: item} for item in corrections)

  # Get the word under the cursor.
  # @param {Editor} editor: editor object.
  # @return {String}: the current word.
  extractWord = (editor) ->
    session = editor.getSession()
    wordRange = getCurrentWordRange(editor)
    return session.getTextRange(wordRange)

  # Sets up spellchecker popup and implements some routines
  # to work on current in the editor.
  setup = (editor) ->
    # Bind newPopup to Alt-Enter editor shortcut.
    editor.commands.addCommand(PopupMgr.startCommand)
    return


  class PopupMgr extends Autocomplete
    constructor: ->
      return

    $init: ->
      HashHandler = require("ace/keyboard/hash_handler").HashHandler
      @keyboardHandler = new HashHandler()
      @keyboardHandler.bindKeys(@commands)

      AcePopup = require("ace/autocomplete/popup").AcePopup
      @popup = new AcePopup()
      @popup.on("click", (e) =>
        @insertMatch()
        e.stop()
      )
      return @popup

    detach: ->
      @editor.keyBinding.removeKeyboardHandler(@keyboardHandler)
      @editor.off("changeSelection", @changeListener)
      @editor.off("blur", @detach)
      @editor.off("mousedown", @detach)
      @editor.off("mousewheel", @detach)

      @popup.hide if @popup and @popup.isOpen()

      @base.detach if @base

      @activated = false
      @completions = null
      @base = null

      return

    changeListener: (e) ->
      if not @activated
        @detach
      cursor = @editor.selection.lead
      if cursor.row isnt @base.row or cursor.column < @base.column
        @detach
      return

    updateCompletions: (keepPopupPosition) ->
      word = extractWord(editor)
      spellChecker = new SpellChecker()
      correctionsItem = spellChecker.getCorrections(word)
      if correctionsItem
        @completions.filtered = convertCorrectionList(correctionsItem)
        @openPopup(editor)
      else
        @detach

    @startCommand:
      name: "spellCheckPopup"
      exec: ->
        if not editor.spellCheckPopup
          editor.spellCheckPopup = new PopupMgr()
        editor.spellCheckPopup.showPopup(editor)
      bindKey: "Alt-Enter"

  return {
    setup: setup
  }

  ##############################################
  # The old PopupManager is here for difference#
  ##############################################

  # Object contains init, show and detach functions for popup
  # and some routines for inner use.
  PopupManager =
    # Bindings for editor keys with PopupManager functions.
    commands:
      "Esc": ->
        PopupManager.detach()
      "Up": ->
        PopupManager.goTo("up")
      "Down": ->
        PopupManager.goTo("down")
      "Return": ->
        PopupManager.insertCorrection()

    # Initial setup for popup.
    # @param {Editor} editor: editor object.
    init: (editor) ->
      @editor = editor
      @activated = false

      HashHandler = require("ace/keyboard/hash_handler").HashHandler
      AcePopup = require("ace/autocomplete/popup").AcePopup

      @popup = new AcePopup(document.body)
      @popup.setTheme(editor.getTheme())
      @popup.setFontSize(editor.getFontSize())
      @popup.on("click", (e) =>
        @insertCorrection()
        e.stop()
      )

      @session = editor.getSession()

      @keyboard = new HashHandler()
      @keyboard.bindKeys(@commands)

      return

    # Show popup in editor.
    # @param {Array} options: list of corrections for the current word.
    show: (options) ->
      @options = options
      @popup.setData(options)

      @activated = true

      position = @editor.getCursorPosition()
      @base = @session.doc.createAnchor(position.row, position.column)

      @editor.keyBinding.addKeyboardHandler(@keyboard)
      @editor.on("change", -> PopupManager.detach())
      @editor.on("changeSelection", -> PopupManager.onChangeSelection())
      @editor.on("blur", -> PopupManager.detach())
      @editor.on("mousedown", -> PopupManager.detach())
      @editor.on("mousewheel", -> PopupManager.detach())
      @editor.$blockScrolling = Infinity

      renderer = @editor.renderer
      lineHeight = renderer.layerConfig.lineHeight
      position = renderer.$cursorLayer.getPixelPosition(@base, true)
      position.left -= @popup.getTextLeftOffset()
      rect = @editor.container.getBoundingClientRect()
      position.top += rect.top - renderer.layerConfig.offset
      position.left += rect.left - @editor.renderer.scrollLeft
      position.left += renderer.gutterWidth

      @popup.show(position, lineHeight)
      return

    # Detach popup from editor.
    detach: ->
      if not @activated
        return

      @popup.hide()
      @base.detach()

      @editor.keyBinding.removeKeyboardHandler(@keyboard)
      @editor.off("change", @onChange)
      @editor.off("changeSelection", @onChangeSelection)
      @editor.off("blur", @onBlur)
      @editor.off("mousedown", @onMouseDown)
      @editor.off("mousewheel", @onMouseWheel)

      @activated = false
      return

    # Insert a selected correction (option) instead of the current word.
    insertCorrection: ->
      @detach()
      correction = @getSelectedCorrection()
      wordRange = getCurrentWordRange(@editor)
      @editor.getSession().replace(wordRange, correction)
      return

    # Change current row in a popup when "up" or "down" listeners triggers.
    # @param {String} where: direction.
    goTo: (where) ->
      row = @popup.getRow()
      max = @popup.getSession().getLength() - 1

      switch where
        when "up"
          if row <= 0 then row = max else row = row - 1
        when "down"
          if row >= max then row = -1 else row = row + 1

      @popup.setRow(row)
      return

    # Pick the chosen option from options object.
    # @return {String}: chosen correction.
    getSelectedCorrection: ->
      row = @popup.getRow()
      return @options[row].value

    onChangeSelection: (e) ->
      if not @activated
        @detach()
        return
      cursor = @editor.selection.lead
      if cursor.row isnt @base.row or cursor.column < @base.column
        @detach()
      return
)