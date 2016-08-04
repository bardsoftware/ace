define((require, exports, module) ->
  getContext = require("ace/ext/papeeria/latex_parsing_context").getContext
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    popoverHandler ?= new class
      options: {
        html: true
        placement: "bottom"
        trigger: "manual"
        title: "Formula"
        container: editor.container
      }

      show: (jqPopoverContainer, content, position) =>
        jqPopoverContainer.css(position)
        @options.content = content
        jqPopoverContainer.popover(popoverHandler.options)
        jqPopoverContainer.popover("show")
        return

      destroy: (jqPopoverContainer) =>
        jqPopoverContainer.popover("destroy")

      popoverExists: (jqPopoverContainer) =>
        jqPopoverContainer.data()? and jqPopoverContainer.data().popover?

      setContent: (jqPopoverContainer, content) =>
        jqPopoverElement = jqPopoverContainer.data().popover.tip().children(".popover-content")
        jqPopoverElement.html(content)

      setPosition: (jqPopoverContainer, position) ->
        jqPopoverElement = jqPopoverContainer.data().popover.tip()
        jqPopoverElement.css(position)


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

    # ch stands for Context Handler
    contextHandler = new class
      @removeRegex: /\\end\{equation\}|\\begin\{equation\}|\\label\{[^\}]*\}/g

      @getEquationRange: (cursorRow) =>
        i = cursorRow
        while getContext(editor.session, i - 1) == "equation"
          i -= 1
        start = i
        while getContext(editor.session, i + 1) == "equation"
          i += 1
        end = i
        return [start, end]

      @getWholeEquation: (start, end) =>
        editor.session.getLines(start, end).join(" ").replace(@removeRegex, "")

      @getPopoverPosition: (row) => {
          top: "#{editor.renderer.textToScreenCoordinates(row + 2, 1).pageY}px"
          left: "#{jqEditorContainer.position().left}px"
        }

      constructor: ->
        [@curStart, @curEnd] = [null, null]
        @currentDelayedUpdateId = null
        @contextPreviewExists = false

      getCurrentFormula: =>
        katex.renderToString(
          @constructor.getWholeEquation(@curStart, @curEnd),
          {displayMode: true}
        )

      initPopover: =>
        {row: cursorRow} = editor.getCursorPosition()
        [@curStart, @curEnd] = @constructor.getEquationRange(cursorRow)
        popoverPosition = @constructor.getPopoverPosition(@curEnd)
        try
          content = @getCurrentFormula()
        catch e
          content = e
        finally
          popoverHandler.show(jqFormula(), content, popoverPosition)

      updatePopover: =>
        try
          content = @getCurrentFormula()
        catch e
          content = e
        finally
          popoverHandler.setContent(jqFormula(), content)

      delayedUpdatePopover: =>
        if @currentDelayedUpdateId?
          clearTimeout(@currentDelayedUpdateId)
        @currentDelayedUpdateId = setTimeout((=> @updatePopover(); @currentDelayedUpdateId = null), 1000)

      updatePosition: =>
        popoverHandler.setPosition(jqFormula(), @constructor.getPopoverPosition(@curEnd))

      handleCurrentContext: =>
        currentContext = getContext(editor.session, editor.getCursorPosition().row)
        if not @contextPreviewExists and currentContext == "equation"
          @contextPreviewExists = true
          if not katex?
            initKaTeX(@initPopover)
          else
            @initPopover()
          editor.on("change", @delayedUpdatePopover)
          editor.session.on("changeScrollTop", @updatePosition)
        else if @contextPreviewExists and currentContext != "equation"
          @contextPreviewExists = false
          editor.off("change", @delayedUpdatePopover)
          editor.session.off("changeScrollTop", @updatePosition)
          popoverHandler.destroy(jqFormula())


    selectionHandler = new class
      hideSelectionPopover: =>
        popoverHandler.destroy(jqFormula())
        editor.off("changeSelection", @hideSelectionPopover)
        editor.session.off("changeScrollTop", @hideSelectionPopover)
        editor.session.off("changeScrollLeft", @hideSelectionPopover)
        return

      renderSelectionUnderCursor: =>
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
          editor.on("changeSelection", @hideSelectionPopover)
          editor.session.on("changeScrollTop", @hideSelectionPopover)
          editor.session.on("changeScrollLeft", @hideSelectionPopover)
          return

      createPopover: (editor) =>
        unless contextHandler.contextPreviewExists
          unless katex?
            initKaTeX(@renderSelectionUnderCursor)
            return
          @renderSelectionUnderCursor()


    editor.commands.addCommand(
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: selectionHandler.createPopover
    )

    editor.on("changeSelection", contextHandler.handleCurrentContext)
    return
  return
)
