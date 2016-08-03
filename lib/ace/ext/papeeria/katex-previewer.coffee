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

    jqFormula = -> $("#formula")

    selectionHandler = {
      hideSelectionPopover: ->
        popoverHandler.destroy(jqFormula())
        editor.off("changeSelection", selectionHandler.hideSelectionPopover)
        editor.session.off("changeScrollTop", selectionHandler.hideSelectionPopover)
        editor.session.off("changeScrollLeft", selectionHandler.hideSelectionPopover)
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
          editor.on("changeSelection", selectionHandler.hideSelectionPopover)
          editor.session.on("changeScrollTop", selectionHandler.hideSelectionPopover)
          editor.session.on("changeScrollLeft", selectionHandler.hideSelectionPopover)
          return

      createPopover: (editor) ->
        unless katex?
          initKaTeX(selectionHandler.renderSelectionUnderCursor)
          return
        selectionHandler.renderSelectionUnderCursor()
    }

    editor.commands.addCommand(
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: selectionHandler.createPopover
    )
    return
  return
)
