# Copyright (C) 2017 BarD Software
foo = null

define((require, exports, module) ->
  {
    EQUATION_CONTEXT
    ERROR_CONTEXT
    getContext
    getContexts
  } = require("ace/ext/papeeria/latex_parsing_context")
  {
    COMMENT_TOKENTYPE
    ERROR_TOKENTYPE
    LABEL_TOKENTYPE
    PARAMETER_TOKENTYPE
    isType
  } = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
  { Range } = require("ace/range")
  {
    ConstrainedTokenIterator
  } = require("ace/ext/papeeria/constrained_token_iterator")


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

    ###*
     * Extracts equation from a given range. Ignores labels and comments.
     *
     * @param {EditSession} session a session to work with
     * @param {Range} range a range of equation
     * @returns {Object} an object with two fields: `labels` -- array of labels
     * collected in the range; `equation` -- equation string with labels and
     * comments filtered out
    ###
    @extractEquation: (session, range) ->
      { start, end } = range
      # Note that 'constrainedTokenIterator' would be one token
      # behind the equation start, so 'constrainedTokenIterator.stepForward()'
      # yields the first token of the equation
      constrainedTokenIterator = new ConstrainedTokenIterator(
        session, range, start.row, start.column
      )
      tokenValues = []
      labels = []
      while true
        token = constrainedTokenIterator.stepForward()
        break if constrainedTokenIterator.outOfRange
        continue if isType(token, COMMENT_TOKENTYPE)
        if isType(token, LABEL_TOKENTYPE)
          if isType(token, PARAMETER_TOKENTYPE)
            labels.push(token.value)
          continue
        tokenValues.push(token.value)

      return { labels: labels, equation: tokenValues.join("") }

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
        { labels, equation } = ContextHandler.extractEquation(@editor.getSession(), @currentRange)
        title = if labels.length == 0 then "Formula" else labels.join(", ")
        return { title: title, content: katex.renderToString(equation, ContextHandler.KATEX_OPTIONS) }
      catch e
        return { title: "Error!", content: e }

    initPopover: =>
      popoverPosition = @getPopoverPosition(@getEquationEndRow())
      { title: title, content: rendered } = @getCurrentFormula()
      @popoverHandler.show(title, rendered, popoverPosition)

    getEquationEndRow: ->
      i = @editor.getCursorPosition().row
      while getContext(@editor.getSession(), i) == EQUATION_CONTEXT
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
        curContext = getContext(@editor.getSession(), cursorPos.row, cursorPos.column)

        if curContext == EQUATION_CONTEXT
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
      currentContext = getContext(@editor.getSession(), cursorPos.row, cursorPos.column)

      if @currentRange? and not @currentRange.contains(cursorPos.row, cursorPos.column)
        @destroyRange()
        @disableUpdates()

      if not @currentRange? and @contextPreviewExists
        @destroyContextPreview()

      if not @currentRange? and currentContext == EQUATION_CONTEXT
        @updateRange()
        @enableUpdates()

      if @currentRange? and not @contextPreviewExists
        @createContextPreview()
    ), 0)


  class EquationRangeHandler
    @DOCUMENT_END_ERROR_CODE: "js.math_preview.error.document_end"
    @EMPTY_LINE_ERROR_CODE: "js.math_preview.error.empty_line"
    @WHITESPACE_LINE_ERROR_CODE: "js.math_preview.error.whitespace_line"

    # empty constructor
    constructor: (@editor) ->

    getBoundary: (session, row, column, start) ->
      summand = if start then -1 else 1
      startRow = row
      curIndex = session.doc.positionToIndex({ row, column }, startRow)
      curRow = row
      curColumn = column
      curContexts = getContexts(session, curRow, curColumn)
      correct = true
      reason = null

      while true
        if correct and curContexts.includes(ERROR_CONTEXT)
          correct = false
          reason = EquationRangeHandler.WHITESPACE_LINE_ERROR_CODE

        if correct and session.getLine(curRow).length == 0
          correct = false
          reason = EquationRangeHandler.EMPTY_LINE_ERROR_CODE

        nextIndex = curIndex + summand
        # In case we're going backwards and have gone beyond the start of
        # 'startRow'
        if nextIndex < 0
          startRow -= 1
          curIndex = session.doc.positionToIndex(
            { row: curRow, column: curColumn },
            startRow
          )
          nextIndex = curIndex + summand

        { row: nextRow, column: nextColumn } = session.doc.indexToPosition(
          nextIndex, startRow
        )

        # That means we're on the last row and last column
        if nextColumn == curColumn and nextRow == curRow
          return {
            correct: false
            reason: EquationRangeHandler.DOCUMENT_END_ERROR_CODE
            row: curRow
            column: curColumn
          }

        nextContexts = getContexts(session, nextRow, nextColumn)
        if not nextContexts.includes(EQUATION_CONTEXT)
          return {
            correct: correct
            reason: reason
            row: curRow
            column: curColumn
          }

        curIndex = nextIndex
        curRow = nextRow
        curColumn = nextColumn
        curContexts = nextContexts

    getEquationRange: (row, column) ->
      start = @getBoundary(@editor.getSession(), row, column, true)
      end = @getBoundary(@editor.getSession(), row, column, false)

      reasons = []
      if not start.correct
        reasons.push(start.reason)
      if not end.correct and not (reasons[0]? and reasons[0] == end.reason)
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
    EquationRangeHandler: EquationRangeHandler
  }
  exports.reset = reset
  exports.SelectionHandler = SelectionHandler
  exports.setupPreviewer = setupPreviewer

  return
)
