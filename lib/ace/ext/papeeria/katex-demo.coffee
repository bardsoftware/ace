define((require, exports, module) ->
    require("ace/ext/jquery")

    $(document).ready( ->
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

        katex = require("ace/ext/katex/katex")

        # Drawing the sample formula in created element
        formulaString = "e^{i \\pi} + 1 = 0"
        katex.render(formulaString, span[0])
    )
)
