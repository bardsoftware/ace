define((require, exports, module) ->
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


  # Class by now provides words checking (used for highlighting) and
  # corrections list for a given word.
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
      correctionsList = @getJson()
      # New JSON structure makes it possible to search for token just like a
      # dictionary key.
      return !correctionsList[token]

    # Return corrections list for token if exists.
    # @param {String} token: token to search in corrections list from server.
    # @return {Array}: list of corrections.
    getCorrections: (token) ->
      return if not @check(token) then @getJson()[token]


  # Sets up spellchecker popup routine and implements
  exports.setupSpellCheckerPopup = (editor) ->
    PopupManager.init(editor)

    # Check if current word is in corrections list.
    # Call showPopup if it's present, do nothing otherwise.
    newPopup = ->
      word = extractWord(editor)
      spellChecker = new SpellChecker()
      correctionsItem = spellChecker.getCorrections(word)
      if correctionsItem
        PopupManager.show(convertCorrectionList(correctionsItem))
      return

    # Bind newPopup to Alt-Enter editor shortcut
    editor.commands.addCommand({
      name: "newPopup",
      bindKey: "Alt-Enter",
      exec: newPopup
    })
    return


  # Get the word under the cursor.
  # @param {Editor} editor: editor object
  # @return {String}
  extractWord = (editor) ->
    session = editor.session
    row = editor.getCursorPosition().row
    wordRange = getCurrentWordRange(editor)
    # getAWordRange returns start and end positions with a trailing
    # whitespace at the end (if there's a one), that's why replace is used
    return session.getTextRange(wordRange).replace(/\s\s*$/, '')

  # Returns Range object that describes current word position.
  # @param {Editor} editor: editor object
  # @return {Range}: current word range.
  getCurrentWordRange = (editor) ->
    session = editor.session
    row = editor.getCursorPosition().row
    col = editor.getCursorPosition().column
    return session.getAWordRange(row, col)

  # Convert an array of string to popup eligible structure.
  # @param {Array} corrections: array of strings with substitution options.
  # @return {Array}: array of jsons, actually.
  convertCorrectionList = (corrections) ->
    options = []
    options.push({caption: item, value: item}) for item in corrections
    return options


  # TODO: incorrect token without correction list.
  # Object contains init, show and detach functions for popup and some
  # routines for inner use.
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

      HashHandler = require("ace/keyboard/hash_handler").HashHandler
      AcePopup = require("ace/autocomplete/popup").AcePopup

      @popup = new AcePopup(document.body)
      @popup.setTheme(editor.getTheme())
      @popup.setFontSize(editor.getFontSize())
      @popup.on("click", (e) =>
        @insertCorrection()
        e.stop()
      )

      @session = editor.session

      @keyboard = new HashHandler()
      @keyboard.bindKeys(@commands)

      @detach if editor?
      return

    # Show popup in editor.
    # @param {Array} options: list of corrections for the current word.
    show: (options) ->
      @options = options

      @popup.setData(options)

      @editor.keyBinding.addKeyboardHandler(@keyboard)

      position = @editor.getCursorPosition()
      @base = @session.doc.createAnchor(position.row, position.column)

      PopupManager.detach if editor?
      @editor.on("change", @changeListener)
      @editor.on("changeSelection", @changeSelectionListener)
      @editor.on("blur", @blurListener)
      @editor.on("mousedown", @mousedownListener)
      @editor.on("mousewheel", @mousewheelListener)
      @editor.$blockScrolling = Infinity

      @activated = true

      renderer = @editor.renderer
      lineHeight = renderer.layerConfig.lineHeight
      pos = renderer.$cursorLayer.getPixelPosition(this.base, true)
      pos.left -= @popup.getTextLeftOffset()
      rect = @editor.container.getBoundingClientRect()
      pos.top += rect.top - renderer.layerConfig.offset
      pos.left += rect.left - @editor.renderer.scrollLeft
      pos.left += renderer.gutterWidth

      @popup.show(pos, lineHeight)
      return

    # Detach popup from editor.
    detach: ->
      @popup.hide() if @popup and @popup.isOpen

      @base.detach() if @base

      @editor.keyBinding.removeKeyboardHandler(@keyboard)

      @editor.off("change", @changeListener)
      @editor.off("changeSelection", @changeSelectionListener)
      @editor.off("blur", @blurListener)
      @editor.off("mousedown", @mousedownListener)
      @editor.off("mousewheel", @mousewheelListener)

      @activated = false
      return

    # Insert selected correction (option) instead of the current word.
    insertCorrection: () ->
      PopupManager.detach()
      row = PopupManager.popup.getRow()
      correction = PopupManager.options[row].value
      wordRange = getCurrentWordRange(PopupManager.editor)
      word = PopupManager.editor.session.getTextRange(wordRange)
      if ' ' in word
        wordRange.end.column--
      PopupManager.editor.session.replace(wordRange, correction)
      return

    # Change current row in a popup when "up" or "down" listeners triggers.
    # @param {String} where: direction.
    goTo: (where) ->
      row = @popup.getRow()
      max = @popup.session.getLength() - 1

      switch where
        when "up"
          if row <= 0 then row = max else row = row - 1
        when "down"
          if row >= max then row = -1 else row = row + 1
        when "start" then row = 0
        when "end" then row = max

      @popup.setRow(row)
      return

    changeListener: (e) ->
      PopupManager.detach()
      return

    changeSelectionListener: (e) ->
      cursor = PopupManager.editor.selection.lead
      if cursor.row isnt @base.row or cursor.column < @base.column
        PopupManager.detach()
      if not @activated
        PopupManager.detach()
      return

    blurListener: (e) ->
      element = document.activeElement
      text = PopupManager.editor.textInput.getElement()
      container = @popup and @popup.container
      if element isnt text and element.parentNode isnt container and e.relatedTarget isnt text
        PopupManager.detach()
      return

    mousedownListener: (e) ->
      PopupManager.detach()
      return

    mousewheelListener: (e) ->
      PopupManager.detach()
      return

  exports.SpellChecker = SpellChecker
  return
)
