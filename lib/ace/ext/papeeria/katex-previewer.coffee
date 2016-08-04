define((require, exports, module) ->
  getContext = require("ace/ext/papeeria/latex_parsing_context").getContext
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
        jqPopoverContainer.data()? and jqPopoverContainer.data().popover?

      setContent: (jqPopoverContainer, content) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip().children(".popover-content")
        jqPopoverElement.html(content)

      setPosition: (jqPopoverContainer, position) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip()
        jqPopoverElement.css(position)
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
    jqFormula = -> $("#formula")

    ch = contextHandler = {
      contextPreviewExists: false

      removeRegex: /\\end\{equation\}|\\begin\{equation\}|\\label\{[^\}]*\}/g

      getEquationRange: (cursorRow) ->
        i = cursorRow
        while getContext(editor.session, i - 1) == "equation"
          i -= 1
        start = i
        while getContext(editor.session, i + 1) == "equation"
          i += 1
        end = i
        return [start, end]

      getWholeEquation: (start, end) ->
        editor.session.getLines(start, end).join(" ").replace(ch.removeRegex, "")

      getPopoverPosition: (row) -> {
          top: "#{editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
          left: "#{jqEditorContainer.position().left}px"
        }

      getCurrentFormula: ->
        katex.renderToString(
          ch.getWholeEquation(ch.curStart, ch.curEnd),
          {displayMode: true}
        )

      initPopover: ->
        {row: cursorRow} = editor.getCursorPosition()
        [ch.curStart, ch.curEnd] = ch.getEquationRange(cursorRow)
        popoverPosition = ch.getPopoverPosition(ch.curEnd)
        try
          content = ch.getCurrentFormula()
        catch e
          content = e
        finally
          popoverHandler.show(jqFormula(), content, popoverPosition)

      updatePopover: ->
        try
          content = ch.getCurrentFormula()
        catch e
          content = e
        finally
          popoverHandler.setContent(jqFormula(), content)

      delayedUpdatePopover: ->
        if ch.currentDelayedUpdateId?
          clearTimeout(ch.currentDelayedUpdateId)
        ch.currentDelayedUpdateId = setTimeout((-> ch.updatePopover(); currentDelayedUpdateId = null), 1000)

      updatePosition: ->
        popoverHandler.setPosition(jqFormula(), ch.getPopoverPosition(ch.curEnd))

      handleCurrentContext: ->
        currentContext = getContext(editor.session, editor.getCursorPosition().row)
        if not ch.contextPreviewExists and currentContext == "equation"
          ch.contextPreviewExists = true
          if not katex?
            initKaTeX(ch.initPopover)
          else
            ch.initPopover()
          editor.on("change", ch.delayedUpdatePopover)
          editor.session.on("changeScrollTop", ch.updatePosition)
        else if ch.contextPreviewExists and currentContext != "equation"
          ch.contextPreviewExists = false
          editor.off("change", ch.delayedUpdatePopover)
          editor.session.off("changeScrollTop", ch.updatePosition)
          popoverHandler.destroy(jqFormula())
    }

    # sh stands for Selection Handler
    sh = selectionHandler = {
      hideSelectionPopover: ->
        popoverHandler.destroy(jqFormula())
        editor.off("changeSelection", sh.hideSelectionPopover)
        editor.session.off("changeScrollTop", sh.hideSelectionPopover)
        editor.session.off("changeScrollLeft", sh.hideSelectionPopover)
        return

      renderSelectionUnderCursor: ->
        try
          cursorPosition = $("textarea.ace_text-input").position()
          popoverPosition = {
            top: "#{cursorPosition.top + 24}px"
            left: "#{cursorPosition.left}px"
          }
          content = katex.renderToString(
            editor.getSelectedText(),
            {displayMode: true}
          )
        catch e
          content = e
        finally
          popoverHandler.show(jqFormula(), content, popoverPosition)
          editor.on("changeSelection", sh.hideSelectionPopover)
          editor.session.on("changeScrollTop", sh.hideSelectionPopover)
          editor.session.on("changeScrollLeft", sh.hideSelectionPopover)
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
      exec: selectionHandler.createPopover
    )

    editor.on("changeSelection", contextHandler.handleCurrentContext)
    return
  return
)
