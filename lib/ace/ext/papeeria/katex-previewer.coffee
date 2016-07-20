define((require, exports, module) ->
  exports.setupPreviewer = (editor) ->
    require("ace/ext/jquery")
    katex = null

    initKaTeX = (onLoaded) ->
      # Adding KaTeX CSS
      cssKatexPath = require.toUrl("../katex/katex.min.css")
      linkKatex = $("<link>").attr(
        rel: "stylesheet"
        href: cssKatexPath
      )
      $("head").append(linkKatex)

      # Adding CSS for demo formula
      cssDemoPath = require.toUrl("./katex-demo.css")
      linkDemo = $("<link>").attr(
        rel: "stylesheet"
        href: cssDemoPath
      )
      $("head").append(linkDemo)

      # Adding DOM element to place formula into
      span = $("<span>").attr(id: "formula")
      $("body").append(span)

      require(["ace/ext/katex/katex"], (katexInner) ->
        katex = katexInner
        onLoaded()
        return
      )
      return

    onLoaded = ->
      selectedText = editor.getSelectedText()
      try
        katex.render(selectedText, $("#formula")[0])
      catch e
        $("#formula").text(e.message)
      return

    callback = (editor) ->
      unless katex?
        initKaTeX(onLoaded)
        return
      onLoaded()

    editor.commands.addCommand({
      name: "previewLaTeXFormula"
      bindKey: {win: "Alt-p", mac: "Alt-p"}
      exec: callback
    })
    return
  return
)
