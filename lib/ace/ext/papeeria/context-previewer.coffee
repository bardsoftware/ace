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

    getTopmostRowNumber = ->
      parseInt(editorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled > div:nth-child(1)").text())

    getPopoverPosition = (cursorRow) ->
      rowSelector = "div.ace_scroller > div > div.ace_layer.ace_text-layer > div:nth-child(#{cursorRow + 2 - getTopmostRowNumber()})"
      console.log(rowSelector)
      cursorRowPosition = editorContainer.find(rowSelector).position()
      top = "#{cursorRowPosition.top + 24}px"

      gutter = editorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled")
      left = gutter.position().left + gutter.width() + 10

      return { top: top, left: left }

    initPopover = ->
      {row: cursorRow} = editor.getCursorPosition()
      popoverPosition = getPopoverPosition(cursorRow)
      try
        content = katex.renderToString(
          editor.session.getLine(cursorRow),
          {displayMode: true}
        )
      # catch e
        # throw e
      finally
        popoverHandler.show($("#formula"), content, popoverPosition)

    updatePopover = ->
      console.log("heyooo")
      {row: cursorRow} = editor.getCursorPosition()
      console.log(cursorRow)
      try
        console.log("here's the content " + editor.session.getLine(cursorRow))
        content = katex.renderToString(
          editor.session.getLine(cursorRow),
          {displayMode: true}
        )
      catch e
        content = e
      finally
        popoverHandler.setContent($("#formula"), content)

    handleCurrentFormula = ->
      {row: cursorRow} = editor.getCursorPosition()
      currentContext = editor.session.getContext(cursorRow)
      if currentContext != "equation"
        if popoverHandler.popoverExists($("#formula"))
          popoverHandler.destroy($("#formula"))
      else
        if popoverHandler.popoverExists($("#formula"))
          updatePopover()
        else
          if not katex?
            initKaTeX(initPopover)
          else
            initPopover()

    editor.on("changeSelection", handleCurrentFormula)

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
