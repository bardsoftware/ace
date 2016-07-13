define((require, exports, module) ->
    exports.setupPreviewer = (editor) ->
        require("ace/ext/jquery")
        katexInitialized = false
        katex = {}

        initKaTeX = ->
            # Adding KaTeX CSS
            cssKatexPath = require.toUrl("../katex/katex.min.css")
            linkKatex = $("<link>").attr("rel", "stylesheet").attr("href", cssKatexPath)
            $("head").append(linkKatex)

            # Adding CSS for demo formula
            cssDemoPath = require.toUrl("./katex-demo.css")
            linkDemo = $("<link>").attr("rel", "stylesheet").attr("href", cssDemoPath)
            $("head").append(linkDemo)

            # Adding DOM element to place formula into
            span = $("<span>").attr("id", "formula")
            $("body").append(span)

            katex = require("ace/ext/katex")
            katexInitialized = true
            return

        editor.commands.addCommand({
            name: "previewLaTeXFormula",
            bindKey: {win: "Alt-p", mac: "Alt-p"},
            exec: (editor) ->
                if not katexInitialized
                    initKaTeX()
                selectedText = editor.getSelectedText()
                katex.render(selectedText, $("#formula")[0])
                return
        })
    return
)
