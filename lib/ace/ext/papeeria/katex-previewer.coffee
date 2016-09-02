define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  TokenIterator = require("ace/token_iterator").TokenIterator
  Range = require("ace/range").Range
  findSurroundingBrackets = require("ace/ext/papeeria/highlighter").findSurroundingBrackets

  trim = (s) ->
    i = 0
    while s[i] == " "
      i += 1
    j = s.length - 1
    while s[j] == " "
      j -= 1
    return s[i..j]

  myKatexLoader = null
  katex = null
  initKaTeX = (onLoaded) ->
    unless myKatexLoader?
      myKatexLoader = (consumer) -> require(["ace/ext/katex"], (katexInner) -> consumer(katexInner))
    myKatexLoader((katexInner) ->
      katex = katexInner
      onLoaded()
    )
    return


  class ContextHandler
    @UPDATE_DELAY: 1000
    @KATEX_OPTIONS = {displayMode: true, throwOnError: false}

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
            argumentRange = ContextHandler.getMacrosArgumentRange(session, {row: tokenPosition.row, column: bracketPosition + 1})
            if argumentRange?
              acceptToken = false
              labelParameters.push(session.getTextRange(argumentRange))
              tokenIterator.stepTo(argumentRange.end.row, argumentRange.end.column + 1)

        if acceptToken
          tokenValues.push(token.value)

        tokenIterator.stepForward()
        token = tokenIterator.getCurrentToken()
        tokenPosition = tokenIterator.getCurrentTokenPosition()

      return [labelParameters, tokenValues.join("")]

    constructor: (@editor, @popoverHandler, @equationRangeHandler, @getFormulaElement) ->
      @jqEditorContainer = $(@editor.container)
      @contextPreviewExists = false

    getPopoverPosition: (row) -> {
        top: "#{@editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
        left: "#{@jqEditorContainer.position().left}px"
      }

    getCurrentFormula: ->
      try
        {row: startRow, column: startColumn} = @curRange.start
        tokenIterator = new ConstrainedTokenIterator(@editor.getSession(), @curRange, startRow, startColumn)
        tokenIterator.stepForward()
        [labelParameters, equationString] = ContextHandler.getWholeEquation(@editor.getSession(), tokenIterator)
        title = if labelParameters.length == 0 then "Formula" else labelParameters.join(", ")
        return [title, katex.renderToString(equationString, ContextHandler.KATEX_OPTIONS)]
      catch e
        return ["Error!", e]

    initPopover: => setTimeout((=>
      popoverPosition = @getPopoverPosition(@getEquationEndRow())
      [title, rendered] = @getCurrentFormula()
      @popoverHandler.show(title, rendered, popoverPosition)
    ), 0)

    getEquationEndRow: ->
      i = @editor.getCursorPosition().row
      while LatexParsingContext.getContext(@editor.getSession(), i) == "equation"
        i += 1
      return i

    updatePosition: =>
      @popoverHandler.setPosition(@getPopoverPosition(@getEquationEndRow()))

    updateRange: ->
      {row: cursorRow, column: cursorColumn} = @editor.getCursorPosition()
      @curRange = @equationRangeHandler.getEquationRange(cursorRow, cursorColumn)

    updatePopover: ->
      if @contextPreviewExists
        [title, rendered] = @getCurrentFormula()
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
        if @contextPreviewExists
          {row: cursorRow, column: cursorColumn} = @editor.getCursorPosition()
          curContext = LatexParsingContext.getContext(@editor.getSession(), cursorRow, cursorColumn)
          if curContext != "equation"
            @destroyContextPreview()
          else
            @updateRange()
            @updatePopover()

    delayedUpdatePopover: =>
      curDocLength = @editor.getSession().getLength()
      if curDocLength != @prevDocLength
        setTimeout(@updatePosition, 0)
        @prevDocLength = curDocLength

      if @currentDelayedUpdateId?
        @lastChangeTime = Date.now()
        return

      @currentDelayedUpdateId = setTimeout(@updateCallback, ContextHandler.UPDATE_DELAY)

    createContextPreview: ->
      @updateRange()
      @contextPreviewExists = true
      if not katex?
        initKaTeX(@initPopover)
      else
        @initPopover()
      @prevDocLength = @editor.getSession().getLength()
      @editor.on("change", @delayedUpdatePopover)
      @editor.getSession().on("changeScrollTop", @updatePosition)

    destroyContextPreview: ->
      @curRange = null
      @contextPreviewExists = false
      @editor.off("change", @delayedUpdatePopover)
      @editor.getSession().off("changeScrollTop", @updatePosition)
      @popoverHandler.destroy()

    handleCurrentContext: => setTimeout((=>
      if @currentDelayedUpdateId?
        return

      {row: cursorRow, column: cursorColumn} = @editor.getCursorPosition()
      currentContext = LatexParsingContext.getContext(@editor.getSession(), cursorRow, cursorColumn)

      # TODO: don't refresh on every cursor move, when the cursor is inside
      # start/end sequence
      if @contextPreviewExists and not @curRange.contains(cursorRow, cursorColumn)
        @destroyContextPreview()

      if not @contextPreviewExists and currentContext == "equation"
        @createContextPreview()
    ), 0)


  class ConstrainedTokenIterator
    constructor: (@session, @range, row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = false
      {row: tokenRow, column: tokenColumn} = @tokenIterator.getCurrentTokenPosition()
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

      {row: tokenRow, column: tokenColumn} = @tokenIterator.getCurrentTokenPosition()
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

      {row: tokenRow, column: tokenColumn} = @tokenIterator.getCurrentTokenPosition()
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
        { type: "string", value: "\\[" }
      ]
      [
        { type: "string", value: "$" }
      ]
      [
        { type: "string", value: "$$" }
      ]
    ]
    @END_EQUATION_TOKEN_SEQUENCES: [
      [
        { type: "storage.type", value: "\\end" }
        { type: "lparen", value: "{" }
        { type: "variable.parameter", value: "equation" }
        { type: "rparen", value: "}" }
      ]
      [
        { type: "string", value: "\\]" }
      ]
      [
        { type: "string", value: "$" }
      ]
      [
        { type: "string", value: "$$" }
      ]
    ]

    # empty constructor
    constructor: (@editor) ->

    @equalTokens: (token1, token2) ->
      return token1.type == token2.type and trim(token1.value) == trim(token2.value)

    getBoundary: (tokenIterator, start) ->
      moveToBoundary = if start then (=> tokenIterator.stepBackward()) else (=> tokenIterator.stepForward())
      moveFromBoundary = if start then (=> tokenIterator.stepForward()) else (=> tokenIterator.stepBackward())
      boundarySequences = (
        if start
        then EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCES
        else EquationRangeHandler.END_EQUATION_TOKEN_SEQUENCES
      )

      # if tokenIterator is initially on the empty line, its current token is null
      if not tokenIterator.getCurrentToken()?
        moveFromBoundary()
        # if tokenIterator.getCurrentToken() is still null, then we're at the end of a file
        if not tokenIterator.getCurrentToken()?
          return null
      else
        # following loop pushes tokenIterator to the end of
        # boundary sequence, if it is inside one
        # The loop isn't executed, if current token is null, because:
        #   a) we don't need to -- if `tokenIterator` is initially on
        #      the empty line, then it is guaranteed not to be inside boundary sequence
        #   b) it can cause bugs -- if we are looking for start sequence and
        #      `tokenIterator` is initially before the start of a document,
        #      current token is null, and after stepping forward `tokenIterator` is on the
        #      start of a document. If start sequence happens to be there, then equation start is
        #      then found without any problem, whereas in this case null should be returned
        for boundarySequence in boundarySequences
          for token in boundarySequence.slice(0).reverse()
            curToken = tokenIterator.getCurrentToken()
            if curToken? and EquationRangeHandler.equalTokens(token, curToken)
              moveFromBoundary()

      curSequence = null
      curSequenceIndex = null
      curEquationBoundary = null
      while true
        moveToBoundary()
        curToken = tokenIterator.getCurrentToken()
        if not curToken?
          return null

        if curSequence != null
          if EquationRangeHandler.equalTokens(
              curSequence[curSequenceIndex],
              curToken)
            curSequenceIndex += 1
          else
            curSequence = null
            curSequenceIndex = null
            curEquationBoundary = null

        if curSequence == null
          for boundarySequence in boundarySequences
            if EquationRangeHandler.equalTokens(boundarySequence[0], curToken)
              curSequence = boundarySequence
              # the first token already matches, so in the 
              # next iteration we match the second one
              curSequenceIndex = 1
              curTokenPosition = tokenIterator.getCurrentTokenPosition()
              curEquationBoundary = {
                row: curTokenPosition.row
                column: curTokenPosition.column + (if start then curToken.value.length else 0)
              }

        if curSequence? and curSequenceIndex >= curSequence.length
          break

      # after finding boundary, tokenIterator is exactly on the last token
      # of ending sequence, so we step back once to avoid errors in case
      # of boundaries with identical starts and ends
      moveFromBoundary()
      return curEquationBoundary

    getEquationRange: (row, column) ->
      tokenIterator = new TokenIterator(@editor.getSession(), row, column)
      end = @getBoundary(tokenIterator, false)
      start = @getBoundary(tokenIterator, true)
      # TODO: handle case when different boundaries were found
      if not (start? and end?)
        return null
      return new Range(start.row, start.column, end.row, end.column)


  exports.ContextHandler = ContextHandler
  exports.ConstrainedTokenIterator = ConstrainedTokenIterator
  exports.EquationRangeHandler = EquationRangeHandler
  exports.setupPreviewer = (editor, popoverHandler, katexLoader) ->
    myKatexLoader = katexLoader
    if not popoverHandler?
      # Adding CSS for demo formula
      cssDemoPath = require.toUrl("./katex-demo.css")
      linkDemo = $("<link>").attr(
        rel: "stylesheet"
        href: cssDemoPath
      )
      $("head").append(linkDemo)

      # Adding DOM element to place formula into
      span = $("<span>").attr(
        id: "formula"
      )
      $("body").append(span)

      jqPopoverContainer = $("#formula")

      popoverHandler = {
        options: {
          html: true
          placement: "bottom"
          trigger: "manual"
          container: editor.container
        }

        show: (title, content, position) ->
          jqPopoverContainer.css(position)
          popoverHandler.options.content = content
          popoverHandler.options.title = title
          jqPopoverContainer.popover(popoverHandler.options)
          jqPopoverContainer.popover("show")
          return

        destroy: ->
          jqPopoverContainer.popover("destroy")

        popoverExists: ->
          jqPopoverContainer.data()?.popover?

        setContent: (title, content) ->
          popoverElement = jqPopoverContainer.data().popover.tip()
          popoverElement.children(".popover-content").html(content)
          popoverElement.children(".popover-title").text(title)

        setPosition: (position) ->
          jqPopoverContainer.data().popover.tip().css(position)
      }

    jqEditorContainer = $(editor.container)
    KATEX_OPTIONS = {displayMode: true, throwOnError: false}

    equationRangeHandler = new EquationRangeHandler(editor)

    contextHandler = new ContextHandler(editor, popoverHandler, equationRangeHandler)

    sh = SelectionHandler = {
      hideSelectionPopover: ->
        popoverHandler.destroy()
        editor.off("changeSelection", sh.hideSelectionPopover)
        editor.getSession().off("changeScrollTop", sh.hideSelectionPopover)
        editor.getSession().off("changeScrollLeft", sh.hideSelectionPopover)
        return

      renderSelectionUnderCursor: ->
        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        cursorPosition = editor.renderer.textToScreenCoordinates(cursorRow, cursorColumn)
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
        return

      createPopover: (editor) ->
        unless ch.contextPreviewExists
          unless katex?
            initKaTeX(sh.renderSelectionUnderCursor)
            return
          sh.renderSelectionUnderCursor()
    }

    editor.commands.addCommand(
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: SelectionHandler.createPopover
    )

    editor.on("changeSelection", contextHandler.handleCurrentContext)
    return
  return
)
