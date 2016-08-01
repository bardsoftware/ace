define((require, exports, module) ->
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

      isVisible: (jqPopoverContainer) ->
        jqPopoverContainer.data().popover.tip().hasClass("in")

      popoverExists: (jqPopoverContainer) ->
        jqPopoverContainer.data()? and jqPopoverContainer.data().popover?

      setContent: (jqPopoverContainer, content, position) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip().children(".popover-content")
        jqPopoverElement.html(content)
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

    [curStart, curEnd] = [null, null]
    prevContext = editor.session.getContext(editor.getCursorPosition().row)
    currentDelayedUpdateId = null

    getEquationRange = (cursorRow) ->
      i = cursorRow
      removeRegex = /\\begin{equation}|\\label{.*}|\\begin{equation*}/g
      while editor.session.getContext(i - 1) == "equation"
        i -= 1
      start = i
      while editor.session.getContext(i + 1) == "equation"
        i += 1
      end = i
      wholeEquation = editor.session.getLines(start, end).join(" ").replace(removeRegex, "")
      return [start, end]

    getWholeEquation = (start, end) ->
      removeRegex =/\\begin\{equation\}|\\label\{[^\}]*\}/g
      wholeEquation = editor.session.getLines(start, end).join(" ").replace(removeRegex, "")
      return wholeEquation

    getTopmostRowNumber = ->
      parseInt(jqEditorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled > div:nth-child(1)").text())

    getPopoverPosition = (row) ->
      rowSelector = "div.ace_scroller > div > div.ace_layer.ace_text-layer > div:nth-child(#{row + 2 - getTopmostRowNumber()})"
      cursorRowPosition = jqEditorContainer.find(rowSelector).position()
      top = "#{cursorRowPosition.top + 24 + 8}px"

      gutter = jqEditorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled")
      left = gutter.position().left + gutter.width() + 10

      return { top: top, left: left }

    getCurrentFormula = ->
      katex.renderToString(
        getWholeEquation(curStart, curEnd)
        {displayMode: true}
      )

    initPopover = ->
      {row: cursorRow} = editor.getCursorPosition()
      [curStart, curEnd] = getEquationRange(cursorRow)
      popoverPosition = getPopoverPosition(curEnd)
      try
        content = getCurrentFormula()
      catch e
        content = e
      finally
        popoverHandler.show(jqFormula(), content, popoverPosition)

    updatePopover = ->
      {row: cursorRow} = editor.getCursorPosition()
      try
        content = getCurrentFormula()
      catch e
        content = e
      finally
        popoverHandler.setContent(jqFormula(), content)

    delayedUpdatePopover = ->
      if currentDelayedUpdateId?
        clearTimeout(currentDelayedUpdateId)
      currentDelayedUpdateId = setTimeout((-> updatePopover(); currentDelayedUpdateId = null), 1000)

    handleCurrentContext = ->
      currentContext = editor.session.getContext(editor.getCursorPosition().row)
      if prevContext != "equation" and currentContext == "equation"
        if not katex?
          initKaTeX(initPopover)
        else
          initPopover()
        editor.on("change", delayedUpdatePopover)
      else if prevContext == "equation" and currentContext != "equation"
        editor.off("change", delayedUpdatePopover)
        popoverHandler.destroy(jqFormula())

      prevContext = currentContext

    editor.on("changeSelection", handleCurrentContext)
  return
)
