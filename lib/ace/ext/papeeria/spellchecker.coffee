define( ->
  # This will be removed and replaced with real data from server.
  # BTW, this is kinda template for data to send from server.
  TEST_JSON_TYPOS = {
    "blablabla": [
      "blah-blah-blah"
      "blabber"
      "blabbed"
      "salable"
    ]
  }


  # Class by now provides words checking (used for highlighting)
  # and also provides corrections list for a given word.
  class SpellChecker
    # By now it's just a stub, but I guess this function will take data from
    # server somehow in future.
    # @return {Object} JSON-list of incorrect words.
    getJson: ->
      return TEST_JSON_TYPOS

    # Check whether token is in JSON incorrect words list.
    # @param {String} token: Token to check.
    # @return {Boolean} False if token is in list, true otherwise.
    check: (token) =>
      return not @getJson()[token]

    # Return corrections list for token if exists.
    # @param {String} token: token to search in corrections list from server.
    # @return {Array}: list of corrections.
    getCorrections: (token) ->
      return if not @check(token) then @getJson()[token]


  # Sets up spellchecker popup and implements some routines
  # to work on current in the editor.
  setupSpellCheckerPopup = (editor) ->
    PopupManager.init(editor)

    # Check if current word is in corrections list.
    # Call PopupManager.show if it's present, do nothing otherwise.
    newPopup = ->
      word = extractWord(editor)
      spellChecker = new SpellChecker()
      correctionsItem = spellChecker.getCorrections(word)
      if correctionsItem
        PopupManager.show(convertCorrectionList(correctionsItem))
      return

    # Bind newPopup to Alt-Enter editor shortcut.
    editor.commands.addCommand({
      name: "newPopup",
      bindKey: "Alt-Enter",
      exec: newPopup
    })
    return


  # Get the word under the cursor.
  # @param {Editor} editor: editor object.
  # @return {String}: the current word.
  extractWord = (editor) ->
    session = editor.getSession()
    wordRange = getCurrentWordRange(editor)
    return session.getTextRange(wordRange)

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
      position = renderer.$cursorLayer.getPixelPosition(this.base, true)
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
      PopupManager.detach()
      correction = PopupManager.getSelectedCorrection()
      wordRange = getCurrentWordRange(PopupManager.editor)
      PopupManager.editor.getSession().replace(wordRange, correction)
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
      row = PopupManager.popup.getRow()
      return PopupManager.options[row].value

    onChangeSelection: (e) ->
      if not @activated
        PopupManager.detach()
        return
      cursor = PopupManager.editor.selection.lead
      if cursor.row isnt @base.row or cursor.column < @base.column
        PopupManager.detach()
      return


  return {
    SpellChecker: SpellChecker
    setupSpellCheckerPopup: setupSpellCheckerPopup
  }
)
