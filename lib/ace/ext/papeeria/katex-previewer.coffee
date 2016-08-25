define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  TokenIterator = require("ace/token_iterator").TokenIterator
  Range = require("ace/range").Range
  findSurroundingBrackets = require("ace/ext/papeeria/highlighter").findSurroundingBrackets


  class ConstrainedTokenIterator
    constructor: (@session, @range, row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      @expired = not @range.contains(row, column)

    getCurrentToken: -> if not @expired then @tokenIterator.getCurrentToken() else null

    getCurrentTokenPosition: -> if not @expired then @tokenIterator.getCurrentTokenPosition() else null

    stepBackward: ->
      @tokenIterator.stepBackward()
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @expired = true
        return null

      {row: tokenRow, column: tokenColumn} = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      if @range.containsRange(tokenRange)
        @expired = false
        return curToken
      else
        @expired = true
        return null

    stepForward: ->
      @tokenIterator.stepForward()
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @expired = true
        return null

      {row: tokenRow, column: tokenColumn} = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      if @range.containsRange(tokenRange)
        @expired = false
        return curToken
      else
        @expired = true
        return null

     stepTo: (row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      @expired = not @range.contains(row, column)


  class EquationRangeHandler
    @BEGIN_EQUATION_TOKEN_SEQUENCE: [
      { type: "storage.type", value: "\\begin" }
      { type: "lparen", value: "{" }
      { type: "variable.parameter", value: "equation" }
      { type: "rparen", value: "}" }
    ]
    @END_EQUATION_TOKEN_SEQUENCE: [
      { type: "storage.type", value: "\\end" }
      { type: "lparen", value: "{" }
      { type: "variable.parameter", value: "equation" }
      { type: "rparen", value: "}" }
    ]

    # empty constructor
    constructor: (@editor) ->

    @equalTokens: (token1, token2) ->
      if token1? and token2?
        return token1.type == token2.type and token1.value == token2.value
      else return if token1? or token2? then false else true

    getEquationStart: (tokenIterator) ->
      # following cycle pushes tokenIterator to the end of
      # beginning sequence, if it is inside one
      for token in EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCE
        if EquationRangeHandler.equalTokens(token, tokenIterator.getCurrentToken())
          tokenIterator.stepForward()
      curSequenceIndex = EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
      curEquationStart = null
      while curSequenceIndex >= 0
        if EquationRangeHandler.equalTokens(
            EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCE[curSequenceIndex],
            tokenIterator.stepBackward())
          if curSequenceIndex == EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
            curTokenPosition = tokenIterator.getCurrentTokenPosition()
            curEquationStart = {
              row: curTokenPosition.row
              column: curTokenPosition.column + tokenIterator.getCurrentToken().value.length
            }
          curSequenceIndex -= 1
        else
          curSequenceIndex = EquationRangeHandler.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
          curEquationStart = null
      return curEquationStart

    getEquationEnd: (tokenIterator) ->
      # following cycle pushes tokenIterator to the start of
      # ending sequence, if it is inside one
      for token in EquationRangeHandler.END_EQUATION_TOKEN_SEQUENCE.slice(0).reverse()
        if EquationRangeHandler.equalTokens(token, tokenIterator.getCurrentToken())
          tokenIterator.stepBackward()
      curSequenceIndex = 0
      curEquationStart = null
      while curSequenceIndex < EquationRangeHandler.END_EQUATION_TOKEN_SEQUENCE.length
        if EquationRangeHandler.equalTokens(
            EquationRangeHandler.END_EQUATION_TOKEN_SEQUENCE[curSequenceIndex],
            tokenIterator.stepForward())
          if curSequenceIndex == 0
            curEquationStart = tokenIterator.getCurrentTokenPosition()
          curSequenceIndex += 1
        else
          curSequenceIndex = 0
          curEquationStart = null
      return curEquationStart

    getEquationRange: (row, column) ->
      tokenIterator = new TokenIterator(@editor.getSession(), row, column)
      end = @getEquationEnd(tokenIterator)
      start = @getEquationStart(tokenIterator)
      return new Range(start.row, start.column, end.row, end.column)


  exports.EquationRangeHandler = EquationRangeHandler
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler ?= {
      options: {
        html: true
        placement: "bottom"
        trigger: "manual"
        container: editor.container
      }

      show: (jqPopoverContainer, title, content, position) ->
        jqPopoverContainer.css(position)
        popoverHandler.options.content = content
        popoverHandler.options.title = title
        jqPopoverContainer.popover(popoverHandler.options)
        jqPopoverContainer.popover("show")
        return

      destroy: (jqPopoverContainer) ->
        jqPopoverContainer.popover("destroy")

      popoverExists: (jqPopoverContainer) ->
        jqPopoverContainer.data()?.popover?

      setContent: (jqPopoverContainer, title, content) ->
        popoverElement = jqPopoverContainer.data().popover.tip()
        popoverElement.children(".popover-content").html(content)
        popoverElement.children(".popover-title").text(title)

      setPosition: (jqPopoverContainer, position) ->
        jqPopoverContainer.data().popover.tip().css(position)
    }

    initKaTeX = (onLoaded) ->
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

      require(["ace/ext/katex"], (katexInner) ->
        katex = katexInner
        onLoaded()
        return
      )
      return

    jqEditorContainer = $(editor.container)
    getFormulaElement = -> $("#formula")
    KATEX_OPTIONS = {displayMode: true, throwOnError: false}

    equationRangeHandler = new EquationRangeHandler(editor)

    ch = ContextHandler = {
      contextPreviewExists: false
      UPDATE_DELAY: 1000
      LABEL_SEQUENCE: [
        {type: "keyword", value: /^\\label$/}
        {type: "lparen", value: /^\{$/}
        {type: "variable.parameter", value: /.*/}
        {type: "rparen", value: /^\}$/}
      ]
      LABEL_PARAMETER_INDEX: 2

      getMacrosArgumentRange: (session, argumentStartPos) ->
        argumentRange = findSurroundingBrackets(session, argumentStartPos)
        if argumentRange.mismatch
          return null
        else
          # increment starting column to not include bracket
          # do not decrement ending column because Range is left-open
          return new Range(argumentRange.start.row, argumentRange.start.column + 1,
                           argumentRange.end.row, argumentRange.end.column)

      getWholeEquation: (tokenIterator) ->

        tokenValues = []
        labelSequenceIndex = 0
        labelParameters = []
        curLabelParameter = null
        curLabelTokens = []

        session = editor.getSession()
        range = tokenIterator.range
        token = tokenIterator.getCurrentToken()
        tokenPosition = tokenIterator.getCurrentTokenPosition()

        while token?

          acceptToken = true
          if token.type == "storage.type" and token.value == "\\label"
            curLine = session.getLine(tokenPosition.row)
            bracketPosition = tokenPosition.column + "\\label".length
            if curLine[bracketPosition] == "{"
              argumentRange = ch.getMacrosArgumentRange(session, {row: tokenPosition.row, column: bracketPosition + 1})
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

      getPopoverPosition: (row) -> {
          top: "#{editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
          left: "#{jqEditorContainer.position().left}px"
        }

      getCurrentFormula: ->
        try
          {row: startRow, column: startColumn} = ch.curRange.start
          tokenIterator = new ConstrainedTokenIterator(editor.getSession(), ch.curRange, startRow, startColumn)
          tokenIterator.stepForward()
          [labelParameters, equationString] = ch.getWholeEquation(tokenIterator)
          title = if labelParameters.length == 0 then "Formula" else labelParameters.join(", ")
          return [title, katex.renderToString(equationString, KATEX_OPTIONS)]
        catch e
          return ["Error!", e]

      initPopover: -> setTimeout((->
        popoverPosition = ch.getPopoverPosition(ch.getEquationEnd())
        [title, rendered] = ch.getCurrentFormula()
        popoverHandler.show(getFormulaElement(), title, rendered, popoverPosition)
      ), 0)

      getEquationEnd: ->
        i = editor.getCursorPosition().row
        while LatexParsingContext.getContext(editor.getSession(), i) == "equation"
          i += 1
        return i

      updatePosition: ->
        popoverHandler.setPosition(getFormulaElement(), ch.getPopoverPosition(ch.getEquationEnd()))

      updateRange: ->
        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        ch.curRange = equationRangeHandler.getEquationRange(cursorRow, cursorColumn)

      updatePopover: ->
        if ch.contextPreviewExists
          [title, rendered] = ch.getCurrentFormula()
          popoverHandler.setContent(getFormulaElement(), title, rendered)

      updateCallback: ->
        if ch.lastChangeTime?
          curTime = Date.now()
          ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.UPDATE_DELAY - (Date.now() - ch.lastChangeTime))
          ch.lastChangeTime = null
        else
          ch.currentDelayedUpdateId = null
          if ch.contextPreviewExists
            curContext = LatexParsingContext.getContext(editor.getSession(), editor.getCursorPosition().row)
            if curContext != "equation"
              ch.destroyContextPreview()
            else
              ch.updateRange()
              ch.updatePopover()

      delayedUpdatePopover: ->
        curDocLength = editor.getSession().getLength()
        if curDocLength != ch.prevDocLength
          setTimeout(ch.updatePosition, 0)
          ch.prevDocLength = curDocLength

        if ch.currentDelayedUpdateId?
          ch.lastChangeTime = Date.now()
          return

        ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.UPDATE_DELAY)

      createContextPreview: ->
        ch.updateRange()
        ch.contextPreviewExists = true
        if not katex?
          initKaTeX(ch.initPopover)
        else
          ch.initPopover()
        ch.prevDocLength = editor.getSession().getLength()
        editor.on("change", ch.delayedUpdatePopover)
        editor.getSession().on("changeScrollTop", ch.updatePosition)

      destroyContextPreview: ->
        ch.curRange = null
        ch.contextPreviewExists = false
        editor.off("change", ch.delayedUpdatePopover)
        editor.getSession().off("changeScrollTop", ch.updatePosition)
        popoverHandler.destroy(getFormulaElement())

      handleCurrentContext: -> setTimeout((->
        if ch.currentDelayedUpdateId?
          return

        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        currentContext = LatexParsingContext.getContext(editor.getSession(), cursorRow)

        if ch.contextPreviewExists and currentContext != "equation"
          ch.destroyContextPreview()

        else if not ch.contextPreviewExists and currentContext == "equation"
          ch.createContextPreview()
      ), 0)
    }

    sh = SelectionHandler = {

      hideSelectionPopover: ->
        popoverHandler.destroy(getFormulaElement())
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
        popoverHandler.show(getFormulaElement(), "Preview", content, popoverPosition)
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

    editor.on("changeSelection", ContextHandler.handleCurrentContext)
    return
  return
)
