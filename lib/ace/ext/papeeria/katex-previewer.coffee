define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
  TokenIterator = require("ace/token_iterator").TokenIterator
  Range = require("ace/range").Range

  getEquationRangeHandler = (editor) ->
    erh = {
      BEGIN_EQUATION_TOKEN_SEQUENCE: [
        {
          type: "storage.type"
          value: "\\begin"
        }
        {
          type: "lparen"
          value: "{"
        }
        {
          type: "variable.parameter"
          value: "equation"
        }
        {
          type: "rparen"
          value: "}"
        }
      ]
      END_EQUATION_TOKEN_SEQUENCE: [
        {
          type: "storage.type"
          value: "\\end"
        }
        {
          type: "lparen"
          value: "{"
        }
        {
          type: "variable.parameter"
          value: "equation"
        }
        {
          type: "rparen"
          value: "}"
        }
      ]

      equalTokens: (token1, token2) ->
        if token1? and token2?
          return token1.type == token2.type and token1.value == token2.value
        else return if token1? or token2? then false else true

      getEquationStart: (tokenIterator) ->
        # following cycle pushes tokenIterator to the end of
        # beginning sequence, if it is inside one
        for token in erh.BEGIN_EQUATION_TOKEN_SEQUENCE
          if erh.equalTokens(token, tokenIterator.getCurrentToken())
            tokenIterator.stepForward()
        curSequenceIndex = erh.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
        curEquationStart = null
        while curSequenceIndex >= 0
          if erh.equalTokens(
              erh.BEGIN_EQUATION_TOKEN_SEQUENCE[curSequenceIndex],
              tokenIterator.stepBackward())
            if curSequenceIndex == erh.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
              curTokenPosition = tokenIterator.getCurrentTokenPosition()
              curEquationStart = {
                row: curTokenPosition.row
                column: curTokenPosition.column + tokenIterator.getCurrentToken().value.length
              }
            curSequenceIndex -= 1
          else
            curSequenceIndex = erh.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
            curEquationStart = null
        return curEquationStart

      getEquationEnd: (tokenIterator) ->
        # following cycle pushes tokenIterator to the start of
        # ending sequence, if it is inside one
        for token in erh.END_EQUATION_TOKEN_SEQUENCE.slice(0).reverse()
          if erh.equalTokens(token, tokenIterator.getCurrentToken())
            tokenIterator.stepBackward()
        curSequenceIndex = 0
        curEquationStart = null
        while curSequenceIndex < erh.END_EQUATION_TOKEN_SEQUENCE.length
          if erh.equalTokens(
              erh.END_EQUATION_TOKEN_SEQUENCE[curSequenceIndex],
              tokenIterator.stepForward())
            if curSequenceIndex == 0
              curEquationStart = tokenIterator.getCurrentTokenPosition()
            curSequenceIndex += 1
          else
            curSequenceIndex = 0
            curEquationStart = null
        return curEquationStart

      getEquationRange: (row, column) ->
        tokenIterator = new TokenIterator(editor.getSession(), row, column)
        end = erh.getEquationEnd(tokenIterator)
        start = erh.getEquationStart(tokenIterator)
        return new Range(start.row, start.column, end.row, end.column)
    }
    return erh

  exports.getEquationRangeHandler = getEquationRangeHandler
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler ?= {
      options: {
        html: true
        placement: "bottom"
        trigger: "manual"
        title: "Formula"
        container: editor.container
      }

      show: (jqPopoverContainer, content, position) ->
        jqPopoverContainer.css(position)
        popoverHandler.options.content = content
        jqPopoverContainer.popover(popoverHandler.options)
        jqPopoverContainer.popover("show")
        return

      destroy: (jqPopoverContainer) ->
        jqPopoverContainer.popover("destroy")

      popoverExists: (jqPopoverContainer) ->
        jqPopoverContainer.data()?.popover?

      setContent: (jqPopoverContainer, content) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip().children(".popover-content").html(content)

      setPosition: (jqPopoverContainer, position) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip().css(position)
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

    erh = EquationRangeHandler = getEquationRangeHandler(editor)

    ch = ContextHandler = {
      contextPreviewExists: false
      UPDATE_DELAY: 1000

      getWholeEquation: (range) ->
        editor.getSession().getTextRange(range)

      getPopoverPosition: (row) -> {
          top: "#{editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
          left: "#{jqEditorContainer.position().left}px"
        }

      getCurrentFormula: ->
        try
          return katex.renderToString(
            ch.getWholeEquation(ch.curRange),
            KATEX_OPTIONS
          )
        catch e
          return e

      initPopover: -> setTimeout((->
        popoverPosition = ch.getPopoverPosition(ch.getEquationEnd())
        popoverHandler.show(getFormulaElement(), ch.getCurrentFormula(), popoverPosition)
      ), 0)

      getEquationEnd: ->
        i = editor.getCursorPosition().row
        while LatexParsingContext.getContext(editor.getSession(), i) == "equation"
          i += 1
        return i

      updatePosition: ->
        setTimeout((-> popoverHandler.setPosition(getFormulaElement(), ch.getPopoverPosition(ch.getEquationEnd()))), 0)

      updateRange: ->
        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        ch.curRange = erh.getEquationRange(cursorRow, cursorColumn)

      updatePopover: ->
        if ch.contextPreviewExists
          popoverHandler.setContent(getFormulaElement(), ch.getCurrentFormula())

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
          ch.updatePosition()
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
        popoverHandler.show(getFormulaElement(), content, popoverPosition)
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
