define((require, exports, module) ->
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler = popoverHandler ? {
      show: (jqPopoverContainer, options) ->
        cursorPosition = $("textarea.ace_text-input").position()
        cursorPosition.top += 24
        cursorPosition.top += "px"
        cursorPosition.left += "px"
        jqPopoverContainer.css(cursorPosition)
        jqPopoverContainer.popover(options)
        jqPopoverContainer.popover("show")
        return

      hide: (jqPopoverContainer) ->
        jqPopoverContainer.popover("destroy")

      isVisible: (popoverElement) ->
        popoverElement.children(".popover").is(":visible")
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
      a = $("<span>").attr(
        id: "formula"
      )
      $("body").append(a)

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
      options = {
        html: true
        placement: "bottom"
        trigger: "manual"
        title: "Formula"
        container: "#editor"
      }
      try
        options.content = katex.renderToString(
          editor.getSelectedText(),
          {displayMode: true}
        )
      catch e
        options.content = e
      finally
        popoverHandler.show($("#formula"), options)
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
