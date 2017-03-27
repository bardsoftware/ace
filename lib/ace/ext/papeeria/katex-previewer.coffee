define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  TokenIterator = require("ace/token_iterator").TokenIterator
  Range = require("ace/range").Range
  findSurroundingBrackets = require("ace/ext/papeeria/highlighter").findSurroundingBrackets


  myKatexLoader = null
  katex = null
  initKaTeX = (onLoaded) ->
    unless myKatexLoader?
      myKatexLoader = (consumer) -> require(["ace/ext/katex"], (katexInner) -> consumer(katexInner))
    myKatexLoader((katexInner) ->
      katex = katexInner
      onLoaded()
    )


  equalTokens = (token1, token2) ->
    return token1.type == token2.type and token1.value.trim() == token2.value.trim()


  class ContextHandler
    @UPDATE_DELAY: 1000
    @KATEX_OPTIONS = { displayMode: true, throwOnError: false }

    @getMacrosArgumentRange: (session, argumentStartPos) ->
      argumentRange = findSurroundingBrackets(session, argumentStartPos)
      if argumentRange.mismatch
        return null
      else
        # increment starting column to not include bracket
        # do not decrement ending column because Range is left-open
        return new Range(argumentRange.start.row, argumentRange.start.column + 1,
                         argumentRange.end.row, argumentRange.end.column)

    @getWholeEquation: (session, tokenIterator) ->
      tokenValues = []
      labelSequenceIndex = 0
      labelParameters = []
      curLabelParameter = null
      curLabelTokens = []

      range = tokenIterator.range
      token = tokenIterator.getCurrentToken()
      tokenPosition = tokenIterator.getCurrentTokenPosition()

      while token?
        acceptToken = true
        if token.type == "storage.type.equation" and token.value == "\\label"
          curLine = session.getLine(tokenPosition.row)
          bracketPosition = tokenPosition.column + "\\label".length
          if curLine[bracketPosition] == "{"
            argumentRange = ContextHandler.getMacrosArgumentRange(session, { row: tokenPosition.row, column: bracketPosition + 1 })
            if argumentRange?
              acceptToken = false
              labelParameters.push(session.getTextRange(argumentRange))
              tokenIterator.stepTo(argumentRange.end.row, argumentRange.end.column + 1)

        if acceptToken
          tokenValues.push(token.value)

        tokenIterator.stepForward()
        token = tokenIterator.getCurrentToken()
        tokenPosition = tokenIterator.getCurrentTokenPosition()

      return { params: labelParameters, equation: tokenValues.join("") }

    constructor: (@editor, @popoverHandler, @equationRangeHandler, @I18N) ->
      @jqEditorContainer = $(@editor.container)
      @contextPreviewExists = false
      @rangeCorrect = false
      @currentRange = null

    getPopoverPosition: (row) -> {
        top: "#{@editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
        left: "#{@jqEditorContainer.position().left}px"
      }

    getCurrentFormula: ->
      try
        if not @currentRange?
          # TODO: Google Analytics call?
          throw "Inconsistent state"
        if not @rangeCorrect
          throw "<div style=\"text-align:center\"><p>#{@messages.join("\n")}</p></div>"
        start = @currentRange.start
        tokenIterator = new ConstrainedTokenIterator(@editor.getSession(), @currentRange, start.row, start.column)
        # if equation content starts on the start of a string, the token on `start` position will be the first token
        # of the equation
        # if it doesn't, the token on `start` position will be the last token of the start sequence
        if start.column != 0
          tokenIterator.stepForward()
        { params: labelParameters, equation: equationString } = ContextHandler.getWholeEquation(@editor.getSession(), tokenIterator)
        title = if labelParameters.length == 0 then "Formula" else labelParameters.join(", ")
        return { title: title, content: katex.renderToString(equationString, ContextHandler.KATEX_OPTIONS) }
      catch e
        return { title: "Error!", content: e }

    initPopover: =>
      popoverPosition = @getPopoverPosition(@getEquationEndRow())
      { title: title, content: rendered } = @getCurrentFormula()
      @popoverHandler.show(title, rendered, popoverPosition)

    getEquationEndRow: ->
      i = @editor.getCursorPosition().row
      while LatexParsingContext.getContext(@editor.getSession(), i) == "equation"
        i += 1
      return i

    updatePosition: =>
      @popoverHandler.setPosition(@getPopoverPosition(@getEquationEndRow()))

    updateRange: ->
      cursorPos = @editor.getCursorPosition()
      {
        correct: @rangeCorrect
        reasons: reasons
        range: @currentRange
      } = @equationRangeHandler.getEquationRange(cursorPos.row, cursorPos.column)
      @messages = (@I18N.text(reason) for reason in reasons)

    destroyRange: ->
      @currentRange = null
      @rangeCorrect = false

    updatePopover: ->
      if @contextPreviewExists
        { title: title, content: rendered } = @getCurrentFormula()
        @popoverHandler.setContent(title, rendered)

    updateCallback: =>
      if @lastChangeTime?
        curTime = Date.now()
        if curTime - @lastChangeTime > ContextHandler.UPDATE_DELAY
          return
        @currentDelayedUpdateId = setTimeout(@updateCallback, ContextHandler.UPDATE_DELAY - (curTime - @lastChangeTime))
        @lastChangeTime = null
      else
        @currentDelayedUpdateId = null
        cursorPos = @editor.getCursorPosition()
        curContext = LatexParsingContext.getContext(@editor.getSession(), cursorPos.row, cursorPos.column)

        if curContext == "equation"
          @updateRange()
        else
          @destroyRange()
          @disableUpdates()

        if @currentRange?
          if @contextPreviewExists
            @updatePopover()
          else
            @createContextPreview()
        else
          @destroyContextPreview()

    delayedUpdatePopover: =>
      curDocLength = @editor.getSession().getLength()
      if @contextPreviewExists and curDocLength != @prevDocLength
        setTimeout(@updatePosition, 0)
        @prevDocLength = curDocLength

      if @currentDelayedUpdateId?
        @lastChangeTime = Date.now()
        return

      @currentDelayedUpdateId = setTimeout(@updateCallback, ContextHandler.UPDATE_DELAY)

    createContextPreview: ->
      @contextPreviewExists = true
      if not katex?
        initKaTeX(@initPopover)
      else
        @initPopover()

    enableUpdates: ->
      # `prevDocLength` trick is exclusively for popover position update
      # Popover position is only changed if we make the new string or
      # delete one, and we can detect that by checking if the length
      # of the document is changed
      @prevDocLength = @editor.getSession().getLength()
      @editor.on("change", @delayedUpdatePopover)
      @editor.getSession().on("changeScrollTop", @updatePosition)

    disableUpdates: ->
      @currentDelayedUpdateId = null
      @editor.off("change", @delayedUpdatePopover)
      @editor.getSession().off("changeScrollTop", @updatePosition)

    destroyContextPreview: ->
      @contextPreviewExists = false
      @popoverHandler.destroy()

    destroyEverything: ->
      @destroyRange()
      @disableUpdates()
      @destroyContextPreview()

    # `setTimeout` is not crucial, but it does help in some narrow cases.
    # The problem is, changing the file in Ace is not always just one event.
    # For instance, when the cursor is on the very end of a line, and then we
    # press `Delete`, this happens:
    #   1)  the cursor is moved to the beginning of the next line
    #   2)  the character behind the cursor is deleted (basically, `Backspace`),
    #       thus removing the empty line
    # Here's the use case where it matters: the math environment is ending with
    # an empty line. The cursor is on the end of a last line of math environment,
    # after which the empty line ends math environment. The popover with an error
    # message is displayed. Here's what happens, when we press `Delete` in that
    # case, if there is no `setTimeout` here:
    #   1)  the cursor is moved to the beginning of an empty line
    #   2)  `handleCurrentContext` triggers: the context is no longer "equation",
    #       so the popover is destroyed
    #   3)  `Backspace` action: we remove the empty line, and the cursor is back
    #       where it was before, but now it is not followed by an empty line
    #   4)  `handleCurrentContext` is triggered again: this time we are inside
    #       "equation" context, so we create the new popover
    # To the user it appears as though the popover is destroyed and then immediately
    # created again, which is not ideal. And overall, in my opinion, it is much cleaner,
    # if `handleCurrentContext` triggers **after** all the `change` events.
    handleCurrentContext: => setTimeout((=>
      if @currentDelayedUpdateId?
        return

      cursorPos = @editor.getCursorPosition()
      currentContext = LatexParsingContext.getContext(@editor.getSession(), cursorPos.row, cursorPos.column)

      if @currentRange? and not @currentRange.contains(cursorPos.row, cursorPos.column)
        @destroyRange()
        @disableUpdates()

      if not @currentRange? and @contextPreviewExists
        @destroyContextPreview()

      if not @currentRange? and currentContext == "equation"
        @updateRange()
        @enableUpdates()

      if @currentRange? and not @contextPreviewExists
        @createContextPreview()
    ), 0)


  class ConstrainedTokenIterator
    constructor: (@session, @range, row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = false
      { row: tokenRow, column: tokenColumn } = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      @outOfRange = not @range.containsRange(tokenRange)

    getCurrentToken: -> if not @outOfRange then @tokenIterator.getCurrentToken() else null

    getCurrentTokenPosition: -> if not @outOfRange then @tokenIterator.getCurrentTokenPosition() else null

    stepBackward: ->
      @tokenIterator.stepBackward()
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = true
        return null

      { row: tokenRow, column: tokenColumn } = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      if @range.containsRange(tokenRange)
        @outOfRange = false
        return curToken
      else
        @outOfRange = true
        return null

    stepForward: ->
      @tokenIterator.stepForward()
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = true
        return null

      { row: tokenRow, column: tokenColumn } = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      if @range.containsRange(tokenRange)
        @outOfRange = false
        return curToken
      else
        @outOfRange = true
        return null

    stepTo: (row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      @outOfRange = not @range.contains(row, column)


  class EquationRangeHandler
    @BEGIN_EQUATION_TOKEN_SEQUENCES: [
      [
        { type: "rparen", value: "}" }
        { type: "variable.parameter", value: "equation" }
        { type: "lparen", value: "{" }
        { type: "storage.type", value: "\\begin" }
      ]
      [
        { type: "rparen", value: "}" }
        { type: "variable.parameter", value: "equation*" }
        { type: "lparen", value: "{" }
        { type: "storage.type", value: "\\begin" }
      ]
      [ { type: "string", value: "\\[" } ]
      [ { type: "string", value: "\\(" } ]
      [ { type: "string", value: "$" } ]
      [ { type: "string", value: "$$" } ]
    ]
    @END_EQUATION_TOKEN_SEQUENCES: [
      [
        { type: "storage.type", value: "\\end" }
        { type: "lparen", value: "{" }
        { type: "variable.parameter", value: "equation" }
        { type: "rparen", value: "}" }
      ]
      [
        { type: "storage.type", value: "\\end" }
        { type: "lparen", value: "{" }
        { type: "variable.parameter", value: "equation*" }
        { type: "rparen", value: "}" }
      ]
      [ { type: "string", value: "\\]" } ]
      [ { type: "string", value: "\\)" } ]
      [ { type: "string", value: "$" } ]
      [ { type: "string", value: "$$" } ]
    ]

    # empty constructor
    constructor: (@editor) ->

    getBoundary: (tokenIterator, start) ->
      moveToBoundary = if start then (=> tokenIterator.stepBackward()) else (=> tokenIterator.stepForward())
      moveFromBoundary = if start then (=> tokenIterator.stepForward()) else (=> tokenIterator.stepBackward())
      boundarySequences = (
        if start
        then EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCES
        else EquationRangeHandler.END_EQUATION_TOKEN_SEQUENCES
      )

      currentToken = tokenIterator.getCurrentToken()
      prevRow = tokenIterator.getCurrentTokenPosition().row
      # TODO: magic string? importing is hard though
      boundaryCorrect = true
      reasonCode = null
      while LatexParsingContext.isType(currentToken, "equation")
        currentToken = moveToBoundary()
        if not currentToken?
          boundaryCorrect = false
          reasonCode = "js.math_preview.error.document_end"
          break
        currentRow = tokenIterator.getCurrentTokenPosition().row
        # Empty string always means that equation state is popped from state stack.
        # Unfortunately, empty string is not tokenized at all, and TokenIterator
        # just skips it altogether, so we have to handle this manually here.
        if Math.abs(currentRow - prevRow) > 1
          boundaryCorrect = false
          reasonCode = "js.math_preview.error.empty_line"
          break
        prevRow = currentRow

      if currentToken? and LatexParsingContext.isType(currentToken, "error")
        boundaryCorrect = false
        reasonCode = "js.math_preview.error.whitespace_line"

      moveFromBoundary()

      { row: curTokenRow, column: curTokenColumn } = tokenIterator.getCurrentTokenPosition()
      curTokenLength = tokenIterator.getCurrentToken().value.length
      return {
        correct: boundaryCorrect
        reason: reasonCode
        row: curTokenRow
        column: curTokenColumn + (if start then 0 else curTokenLength)
      }

    getEquationRange: (row, column) ->
      tokenIterator = new TokenIterator(@editor.getSession(), row, column)
      start = @getBoundary(tokenIterator, true)
      tokenIterator = new TokenIterator(@editor.getSession(), row, column)
      end = @getBoundary(tokenIterator, false)

      reasons = []
      if not start.correct
        reasons.push(start.reason)
      if not end.correct
        reasons.push(end.reason)

      return {
        correct: start.correct and end.correct
        reasons: reasons
        range: new Range(start.row, start.column, end.row, end.column)
      }


  myContextHandler = null
  reset = -> if myContextHandler?.contextPreviewExists then myContextHandler.destroyEverything()

  sh = SelectionHandler = {
    hideSelectionPopover: ->
      popoverHandler.destroy()
      editor.off("changeSelection", sh.hideSelectionPopover)
      editor.getSession().off("changeScrollTop", sh.hideSelectionPopover)
      editor.getSession().off("changeScrollLeft", sh.hideSelectionPopover)

    renderSelectionUnderCursor: ->
      cursorPos = editor.getCursorPosition()
      cursorPosition = editor.renderer.textToScreenCoordinates(cursorPos.row, cursorPos.column)
      popoverPosition = {
        top: "#{cursorPosition.pageY + 24}px"
        left: "#{cursorPosition.pageX}px"
      }
      content = katex.renderToString(
        editor.getSelectedText(),
        KATEX_OPTIONS
      )
      popoverHandler.show("Preview", content, popoverPosition)
      editor.on("changeSelection", sh.hideSelectionPopover)
      editor.getSession().on("changeScrollTop", sh.hideSelectionPopover)
      editor.getSession().on("changeScrollLeft", sh.hideSelectionPopover)

    createPopover: (editor) ->
      if not myContextHandler?.contextPreviewExists
        if not katex?
          initKaTeX(sh.renderSelectionUnderCursor)
          return
        sh.renderSelectionUnderCursor()
  }

  setupPreviewer = (editor, popoverHandler, katexLoader, I18N) ->
    myKatexLoader = katexLoader
    equationRangeHandler = new EquationRangeHandler(editor)
    myContextHandler = new ContextHandler(editor, popoverHandler, equationRangeHandler, I18N)
    editor.on("changeSelection", myContextHandler.handleCurrentContext)

  exports.testExport = {
    ContextHandler: ContextHandler
    ConstrainedTokenIterator: ConstrainedTokenIterator
    EquationRangeHandler: EquationRangeHandler
  }
  exports.reset = reset
  exports.SelectionHandler = SelectionHandler
  exports.setupPreviewer = setupPreviewer

  return
)
