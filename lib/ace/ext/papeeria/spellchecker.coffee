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


  # Class by now provides highlighting of words that takes from JSON and
  # popup displaying to choose corrections.
  #
  # TODO: incorrect token without correction list.
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
      if not @check(token)
        return @getJson()[token]
      else
        return

  # Implements some routines to show popup for spellchecker (to choose a
  # proper substitution for a typo). Also binds popup to an editor's shortcut
  # and listeners.
  exports.setupSpellCheckerPopup = (editor) ->
    # Take corrections for current word and shows them in a popup.
    # @param {Array} options: popup has a setData function that takes some
    # sort of structure, it needs to be replicated so popup could show options
    # for substitution.
    #
    # Some of this code is duplicated from autocomplete.js so it's just left
    # as-is (by now?)
    showPopup = (options) =>
      AcePopup = require("ace/autocomplete/popup").AcePopup
      util = require("ace/autocomplete/util")
      HashHandler = require("ace/keyboard/hash_handler").HashHandler
      event = require("ace/lib/event")

      # Set all variables and listeners to show popup.
      @init = ->
        @popup = new AcePopup(document.body)
        @popup.setData(options)
        @popup.setTheme(editor.getTheme())
        @popup.setFontSize(editor.getFontSize())
        @popup.on("click", (e) =>
          @insertCorrection()
          e.stop()
        )

        session = editor.session
        position = editor.getCursorPosition()
        @base = session.doc.createAnchor(position.row, position.column)

        @keyboard = new HashHandler()
        @keyboard.bindKeys(@commands)
        editor.keyBinding.addKeyboardHandler(@keyboard)

        @detach if editor?
        editor.on("change", @changeListener)
        editor.on("changeSelection", @changeSelectionListener)
        editor.on("blur", @blurListener)
        editor.on("mousedown", @mousedownListener)
        editor.on("mousewheel", @mousewheelListener)
        editor.$blockScrolling = Infinity

        @activated = true

        renderer = editor.renderer
        lineHeight = renderer.layerConfig.lineHeight
        pos = renderer.$cursorLayer.getPixelPosition(this.base, true)
        pos.left -= @popup.getTextLeftOffset()
        rect = editor.container.getBoundingClientRect()
        pos.top += rect.top - renderer.layerConfig.offset
        pos.left += rect.left - editor.renderer.scrollLeft
        pos.left += renderer.gutterWidth
  
        @popup.show(pos, lineHeight)
        return

      # Change current row in a popup when "up" or "down" listeners triggers.
      # @param {String} where: direction.
      @goTo = (where) ->
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

      # Unset listeners and hide popup.
      @detach = ->
        @popup.hide() if @popup and @popup.isOpen
        @base.detach() if @base
        editor.keyBinding.removeKeyboardHandler(@keyboard)

        editor.off("change", @changeListener)
        editor.off("changeSelection", @changeSelectionListener)
        editor.off("blur", @blurListener)
        editor.off("mousedown", @mousedownListener)
        editor.off("mousewheel", @mousewheelListener)

        @activated = false
        return

      @commands = {
        "Esc": =>
          @detach()
        "Up": =>
          @goTo("up")
        "Down": =>
          @goTo("down")
        "Return": =>
          @insertCorrection()
      }

      @changeListener = (e) =>
        @detach()
        return

      @changeSelectionListener = (e) =>
        cursor = editor.selection.lead
        if cursor.row isnt @base.row or cursor.column < @base.column
          @detach()
        if not @activated
          @detach()
        return

      @blurListener = (e) =>
        element = document.activeElement
        text = editor.textInput.getElement()
        container = @popup and @popup.container
        if element isnt text and element.parentNode isnt container and e.relatedTarget isnt text
          @detach()
        return

      @mousedownListener = (e) =>
        @detach()
        return

      @mousewheelListener = (e) =>
        @detach()
        return

      @insertCorrection = () =>
        @detach()
        row = @popup.getRow()
        correction = options[row].value
        wordRange = getCurrentWordRange()
        word = editor.session.getTextRange(wordRange)
        if ' ' in word
          wordRange.end.column--
        editor.session.replace(wordRange, correction)
        return

      @init()
      return

    # Convert an array of string to popup eligible structure.
    # @param {Array} corrections: array of strings with substitution options.
    # @returns {Array}: array of jsons, actually.
    convertCorrectionList = (corrections) ->
      options = []
      options.push({caption: item, value: item}) for item in corrections
      return options

    # Returns Range object that describes current word position.
    # @param {Range}: current word range.
    getCurrentWordRange = ->
      session = editor.session
      row = editor.getCursorPosition().row
      col = editor.getCursorPosition().column
      return session.getAWordRange(row, col)

    # Get the word under the cursor.
    # @returns {String}
    extractWord = ->
      session = editor.session
      row = editor.getCursorPosition().row
      wordRange = getCurrentWordRange()
      start = wordRange.start.column
      end = wordRange.end.column
      # getAWordRange returns start and end positions with a trailing
      # whitespace at the end (if there's a one), that's why replace is used
      return session.getTextRange(wordRange).replace(/\s\s*$/, '')

    # Check if current word is in corrections list.
    # Call showPopup if it's present, do nothing otherwise.
    tryPopup = ->
      word = extractWord()
      spellChecker = new SpellChecker()
      correctionsItem = spellChecker.getCorrections(word)
      if correctionsItem
        showPopup(convertCorrectionList(correctionsItem))
      return

    # Bind a shortcut to tryPopup callback.
    editor.commands.addCommand({
      name: "test",
      bindKey: "Alt-Enter",
      exec: tryPopup
    })

    return

  exports.SpellChecker = SpellChecker
  return
)
