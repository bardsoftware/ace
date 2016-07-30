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

    callbackHidePopover = ->
      popoverHandler.destroy($("#formula"))
      editor.off("changeSelection", callbackHidePopover)
      editor.session.off("changeScrollTop", callbackHidePopover)
      editor.session.off("changeScrollLeft", callbackHidePopover)
      return

    renderFormulaToPopoverUnderCursor = ->
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
        popoverHandler.show($("#formula"), content, popoverPosition)
        editor.on("changeSelection", callbackHidePopover)
        editor.session.on("changeScrollTop", callbackHidePopover)
        editor.session.on("changeScrollLeft", callbackHidePopover)
        return

    createPopover = (editor) ->
      unless katex?
        initKaTeX(renderFormulaToPopoverUnderCursor)
        return
      renderFormulaToPopoverUnderCursor()

    editor.commands.addCommand(
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: createPopover
    )
    return
  return
)