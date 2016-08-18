define((require, exports, module) ->
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")
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
    TokenIterator = require("ace/token_iterator").TokenIterator
    Range = require("ace/range").Range

    erh = EquationRangeHandler = {
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
      rangeCache: {}

      compareTokens: (token1, token2) ->
        (not token1? and not token2?) or token1? and token2? and token1.type == token2.type and token1.value == token2.value

      getEquationStart: (tokenIterator) ->
        # following cycle pushes tokenIterator to the end of
        # beginning sequence, if it is inside one
        for token in erh.BEGIN_EQUATION_TOKEN_SEQUENCE
          if erh.compareTokens(token, tokenIterator.getCurrentToken())
            tokenIterator.stepForward()
        curSequenceIndex = erh.BEGIN_EQUATION_TOKEN_SEQUENCE.length - 1
        curEquationStart = null
        while curSequenceIndex >= 0
          if erh.compareTokens(erh.BEGIN_EQUATION_TOKEN_SEQUENCE[curSequenceIndex], tokenIterator.stepBackward())
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
          if erh.compareTokens(token, tokenIterator.getCurrentToken())
            tokenIterator.stepBackward()
        curSequenceIndex = 0
        curEquationStart = null
        while curSequenceIndex < erh.END_EQUATION_TOKEN_SEQUENCE.length
          if erh.compareTokens(erh.END_EQUATION_TOKEN_SEQUENCE[curSequenceIndex], tokenIterator.stepForward())
            if curSequenceIndex == 0
              curEquationStart = tokenIterator.getCurrentTokenPosition()
            curSequenceIndex += 1
          else
            curSequenceIndex = 0
            curEquationStart = null
        return curEquationStart

      getEquationRange: (row, column) ->
        start = erh.getEquationStart(new TokenIterator(editor.getSession(), row, column))
        end = erh.getEquationEnd(new TokenIterator(editor.getSession(), row, column))
        return new Range(start.row, start.column, end.row, end.column)
        erh.rangeCache[[row, column]] = range
    }


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

      initPopover: ->
        ch.updateRange()
        popoverPosition = ch.getPopoverPosition(ch.curRange.end.row)
        popoverHandler.show(getFormulaElement(), ch.getCurrentFormula(), popoverPosition)
        editor.on("change", ch.delayedUpdatePopover)
        editor.getSession().on("changeScrollTop", ch.updatePosition)

      updatePosition: ->
        popoverHandler.setPosition(getFormulaElement(), ch.getPopoverPosition(ch.curRange.end.row))

      updateRange: ->
        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        ch.curRange = erh.getEquationRange(cursorRow, cursorColumn)

      updatePopover: ->
        ch.updatePosition()
        popoverHandler.setContent(getFormulaElement(), ch.getCurrentFormula())

      updateCallback: ->
        if ch.lastChangeTime?
          curTime = Date.now()
          ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.UPDATE_DELAY - (Date.now() - ch.lastChangeTime))
          ch.lastChangeTime = null
        else
          ch.updatePopover()
          ch.currentDelayedUpdateId = null

      delayedUpdatePopover: ->
        ch.updateRange()
        ch.updatePosition()
        if ch.currentDelayedUpdateId?
          ch.lastChangeTime = Date.now()
          return
        ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.UPDATE_DELAY)

      handleCurrentContext: ->
        {row: cursorRow, column: cursorColumn} = editor.getCursorPosition()
        currentContext = LatexParsingContext.getContext(editor.getSession(), cursorRow)
        if not ch.contextPreviewExists and currentContext == "equation"
          ch.contextPreviewExists = true
          if not katex?
            initKaTeX(ch.initPopover)
          else
            ch.initPopover()
        else if ch.curRange? and not ch.curRange.contains(cursorRow, cursorColumn)
        #
        # The commented check does not work, because if we create new line while
        # inside the equation on the last line of the equation, then context
        # is not updated for another 700 ms, and this new line does not have
        # `equation` context, whereas range is updated on every change.
        #
        # else if ch.contextPreviewExists and currentContext != "equation"
          ch.contextPreviewExists = false
          editor.off("change", ch.delayedUpdatePopover)
          editor.getSession().off("changeScrollTop", ch.updatePosition)
          popoverHandler.destroy(getFormulaElement())
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
