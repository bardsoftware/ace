define((require, exports, module) ->
  exports.setupPreviewer = (editor) ->
    katex = null

    initKaTeX = (onLoaded) ->
      # Adding CSS for demo formula
      cssDemoPath = require.toUrl("./katex-demo.css")
      linkDemo = $("<link>").attr(
        rel: "stylesheet"
        href: cssDemoPath
      )
      $("head").append(linkDemo)

      # Adding DOM element to place formula into
      a = $("<a>").attr(
        href: "#"
        id: "formula"
        "data-toggle": "popover"
      )
      $("body").append(a)

      require(["ace/ext/katex"], (katexInner) ->
        katex = katexInner
        onLoaded()
        return
      )
      return

    options = {
      html: true
      placement: "bottom"
      trigger: "manual"
      title: "Formula"
      content: -> katex.renderToString(editor.getSelectedText(), {displayMode: true})
      container: "#editor"
    }

    onLoaded = ->
      try
        popoverPosition = $("textarea.ace_text-input").position()
        popoverPosition.top += 24
        $("#formula").css(popoverPosition)
        $("#formula").popover(options)
        $("#formula").popover("show")
      catch e
        console.log(e.message)
      return

    popoverShown = false

    callback = (editor) ->
      if popoverShown
        destroyPopover()
        popoverShown = false
      else
        createPopover(editor)
        popoverShown = true
      return

    destroyPopover = -> $("#formula").popover("destroy")

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
