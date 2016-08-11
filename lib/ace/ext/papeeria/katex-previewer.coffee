define((require, exports, module) ->
  latexContextParser = require("ace/ext/papeeria/latex_parsing_context")
  exports.setupPreviewer = (editor, popoverHandler) ->
    katex = null
    bannedTokenSequences = null
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
      # Loading banned sequences file
      response = $.getJSON(require.toUrl("./banned_token_sequences.json"))
      setTimeout((-> bannedTokenSequences = response.responseJSON), 0)

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
      updateDelay: 1000

      getEquationRange: (cursorRow) ->
        i = cursorRow
        while latexContextParser.getContext(editor.session, i - 1) == "equation"
          i -= 1
        start = i
        while latexContextParser.getContext(editor.session, i + 1) == "equation"
          i += 1
        end = i
        return [start, end]

      compareTokens: (tokenToCheck, tokenToMatch) ->
        return tokenToCheck["type"] == tokenToMatch["type"] and (new RegExp(tokenToMatch["value"])).test(tokenToCheck["value"])

      filterTokens: (tokens) ->
        i = 0
        rangesToDelete = []
        while i < tokens.length
          j = 0
          while j < bannedTokenSequences.length
            curSequenceToMatch = bannedTokenSequences[j]
            k = 0
            while k < curSequenceToMatch.length and ch.compareTokens(tokens[i + k], curSequenceToMatch[k])
              k += 1
            if k == curSequenceToMatch.length
              rangesToDelete.push([i, i + k])
              i = i + k
              break
            j += 1
          if j == bannedTokenSequences.length
            i += 1

        i = 0
        j = 0
        filteredTokens = []
        while i < tokens.length
          if j < rangesToDelete.length and i == rangesToDelete[j][0]
            i = rangesToDelete[j][1]
            j += 1
          else
            filteredTokens.push(tokens[i])
            i += 1

        return filteredTokens

      getWholeEquation: (start, end) ->
        tokens = []
        for i in [start..end]
          $.merge(tokens, editor.session.getTokens(i))
        filteredTokens = ch.filterTokens(tokens)
        return filteredTokens.map((val) -> val["value"]).join(" ")

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
        cursorRow = editor.getCursorPosition().row
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

      updateCallback: ->
        if ch.lastChangeTime?
          curTime = Date.now()
          ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.updateDelay - (Date.now() - ch.lastChangeTime))
          ch.lastChangeTime = null
        else
          ch.updatePopover()
          ch.currentDelayedUpdateId = null

      delayedUpdatePopover: ->
        if ch.currentDelayedUpdateId?
          ch.lastChangeTime = Date.now()
          return
        ch.currentDelayedUpdateId = setTimeout(ch.updateCallback, ch.updateDelay)

      updatePosition: ->
        popoverHandler.setPosition(jqFormula(), ch.getPopoverPosition(ch.curEnd))

      handleCurrentContext: ->
        currentContext = latexContextParser.getContext(editor.session, editor.getCursorPosition().row)
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
