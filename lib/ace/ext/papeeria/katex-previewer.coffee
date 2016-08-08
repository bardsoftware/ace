define((require, exports, module) ->
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler = popoverHandler ? {
      options: {
        html: true
        placement: "bottom"
        trigger: "manual"
        title: "Formula"
        container: "#editor"
      }

      show: (jqPopoverContainer, content) ->
        cursorPosition = $("textarea.ace_text-input").position()
        jqPopoverContainer.css({
          top: "#{cursorPosition.top + 24}px"
          left: "#{cursorPosition.left}px"
        })
        popoverHandler.options.content = content
        jqPopoverContainer.popover(popoverHandler.options)
        jqPopoverContainer.popover("show")
        return

      hide: (jqPopoverContainer) ->
        jqPopoverContainer.popover("destroy")

      isVisible: (jqPopoverElement) ->
        jqPopoverElement.children(".popover").is(":visible")
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
      popoverHandler.hide($("#formula"))
      editor.off("changeSelection", callbackHidePopover)
      editor.session.off("changeScrollTop", callbackHidePopover)
      editor.session.off("changeScrollLeft", callbackHidePopover)
      return

    onLoaded = ->
      try
        content = katex.renderToString(
          editor.getSelectedText(),
          {displayMode: true}
        )
      catch e
        content = e
      finally
        popoverHandler.show($("#formula"), content)
        editor.on("changeSelection", callbackHidePopover)
        editor.session.on("changeScrollTop", callbackHidePopover)
        editor.session.on("changeScrollLeft", callbackHidePopover)
        return

    callback = (editor) -> createPopover(editor)

    destroyPopover = -> popoverHandler.hide($("#formula"))

    createPopover = (editor) ->
      unless katex?
        initKaTeX(onLoaded)
        return
      onLoaded()

    editor.commands.addCommand(
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: callback
    )
    return
  return
)
