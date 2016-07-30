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

    editorContainer = $(editor.container)

    [curStart, curEnd] = [null, null]
    prevContext = editor.session.getContext(editor.getCursorPosition().row)

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
      parseInt(editorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled > div:nth-child(1)").text())

    getPopoverPosition = (row) ->
      rowSelector = "div.ace_scroller > div > div.ace_layer.ace_text-layer > div:nth-child(#{row + 2 - getTopmostRowNumber()})"
      console.log(rowSelector)
      cursorRowPosition = editorContainer.find(rowSelector).position()
      top = "#{cursorRowPosition.top + 24 + 8}px"

      gutter = editorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled")
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
        popoverHandler.show($("#formula"), content, popoverPosition)

    updatePopover = ->
      console.log("heyooo")
      {row: cursorRow} = editor.getCursorPosition()
      try
        content = getCurrentFormula()
      catch e
        content = e
      finally
        popoverHandler.setContent($("#formula"), content)

    handleCurrentContext = ->
      currentContext = editor.session.getContext(editor.getCursorPosition().row)
      if prevContext != "equation" and currentContext == "equation"
        if not katex?
          initKaTeX(initPopover)
        else
          initPopover()
        editor.on("change", updatePopover)
      else if prevContext == "equation" and currentContext != "equation"
        editor.off("change", updatePopover)
        popoverHandler.destroy($("#formula"))

      prevContext = currentContext

    editor.on("changeSelection", handleCurrentContext)

    # callbackHidePopover = ->
    #   popoverHandler.destroy($("#formula"))
    #   editor.off("changeSelection", callbackHidePopover)
    #   editor.session.off("changeScrollTop", callbackHidePopover)
    #   editor.session.off("changeScrollLeft", callbackHidePopover)
    #   return

    # renderFormulaToPopoverUnderCursor = ->
    #   try
    #     cursorPosition = $("textarea.ace_text-input").position()
    #     popoverPosition = {
    #       top: "#{cursorPosition.top + 24}px"
    #       left: "#{cursorPosition.left}px"
    #     }
    #     content = katex.renderToString(
    #       editor.getSelectedText(),
    #       {displayMode: true}
    #     )
    #   catch e
    #     content = e
    #   finally
    #     popoverHandler.show($("#formula"), content, popoverPosition)
    #     editor.on("changeSelection", callbackHidePopover)
    #     editor.session.on("changeScrollTop", callbackHidePopover)
    #     editor.session.on("changeScrollLeft", callbackHidePopover)
    #     return

    # createPopover = (editor) ->
    #   unless katex?
    #     initKaTeX(renderFormulaToPopoverUnderCursor)
    #     return
    #   renderFormulaToPopoverUnderCursor()

    # editor.commands.addCommand(
    #   name: "previewLaTeXFormula"
    #   bindKey: {win: "Alt-p", mac: "Alt-p"}
    #   exec: createPopover
    # )
    # return
  return
)
