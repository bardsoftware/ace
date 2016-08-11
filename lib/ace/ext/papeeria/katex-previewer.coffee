define((require, exports, module) ->
  LatexContextParser = require("ace/ext/papeeria/latex_parsing_context")
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler = popoverHandler ? {
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

    ch = ContextHandler = {
      contextPreviewExists: false
      UPDATE_DELAY: 1000
      REMOVE_REGEX: /\\end\{equation\}|\\begin\{equation\}/g

      getEquationRange: (cursorRow) ->
        i = cursorRow
        while LatexContextParser.getContext(editor.getSession(), i - 1) == "equation"
          i -= 1
        start = i
        i = cursorRow
        while LatexContextParser.getContext(editor.getSession(), i + 1) == "equation"
          i += 1
        end = i
        return [start, end]

      getWholeEquation: (start, end) ->
        editor.session.getLines(start, end).join(" ").replace(ch.REMOVE_REGEX, "")

      getPopoverPosition: (row) -> {
          top: "#{editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
          left: "#{jqEditorContainer.position().left}px"
        }

      getCurrentFormula: ->
        katex.renderToString(
          ch.getWholeEquation(ch.curStart, ch.curEnd),
          KATEX_OPTIONS
        )

      initPopover: ->
        cursorRow = editor.getCursorPosition().row
        [ch.curStart, ch.curEnd] = ch.getEquationRange(cursorRow)
        popoverPosition = ch.getPopoverPosition(ch.curEnd)
        popoverHandler.show(getFormulaElement(), ch.getCurrentFormula(), popoverPosition)

      updatePopover: ->
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
        if ch.currentDelayedUpdateId?
          ch.lastChangeTime = Date.now()
          return
        ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.UPDATE_DELAY)

      updatePosition: ->
        popoverHandler.setPosition(getFormulaElement(), ch.getPopoverPosition(ch.curEnd))

      handleCurrentContext: ->
        currentContext = LatexContextParser.getContext(editor.getSession(), editor.getCursorPosition().row)
        if not ch.contextPreviewExists and currentContext == "equation"
          ch.contextPreviewExists = true
          if not katex?
            initKaTeX(ch.initPopover)
          else
            ch.initPopover()
          editor.on("change", ch.delayedUpdatePopover)
          editor.getSession().on("changeScrollTop", ch.updatePosition)
        else if ch.contextPreviewExists and currentContext != "equation"
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
