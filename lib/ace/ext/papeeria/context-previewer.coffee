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

    jqEditorContainer = $(editor.container)
    jqFormula = -> $("#formula")

    # ch stands for Context Handler
    ch = {
      removeRegex: /\\end\{equation\}|\\begin\{equation\}|\\label\{[^\}]*\}/g

      getEquationRange: (cursorRow) ->
        i = cursorRow
        while editor.session.getContext(i - 1) == "equation"
          i -= 1
        start = i
        while editor.session.getContext(i + 1) == "equation"
          i += 1
        end = i
        return [start, end]

      getWholeEquation: (start, end) ->
        editor.session.getLines(start, end).join(" ").replace(ch.removeRegex, "")

      getTopmostRowNumber: ->
        parseInt(jqEditorContainer.find("div.ace_gutter > div.ace_layer.ace_gutter-layer.ace_folding-enabled > div:nth-child(1)").text())

      getPopoverPosition: (row) ->
        secondRowSelector = "div.ace_scroller > div > div.ace_layer.ace_text-layer > div:nth-child(2)"
        jqSecondRow = jqEditorContainer.find(secondRowSelector)
        secondRowPosition = jqSecondRow.position()
        pxRowHeight = jqSecondRow.height()
        relativeRow = row + 1 - ch.getTopmostRowNumber()
        top = "#{secondRowPosition.top + pxRowHeight * (relativeRow + 1)}px"

        left = jqEditorContainer.position().left

        return {
          top: top
          left: left
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
        currentContext = editor.session.getContext(editor.getCursorPosition().row)
        if ch.prevContext != "equation" and currentContext == "equation"
          if not katex?
            initKaTeX(ch.initPopover)
          else
            ch.initPopover()
          editor.on("change", ch.delayedUpdatePopover)
          editor.session.on("changeScrollTop", ch.updatePosition)
        else if ch.prevContext == "equation" and currentContext != "equation"
          editor.off("change", ch.delayedUpdatePopover)
          editor.session.off("changeScrollTop", ch.updatePosition)
          popoverHandler.destroy(jqFormula())

        ch.prevContext = currentContext
    }

    editor.on("changeSelection", ch.handleCurrentContext)
  return
)
