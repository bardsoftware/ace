define (require, exports, module) ->
    require "ace/ext/jquery"

    $(document).ready ->
        # Adding KaTeX CSS
        cssKatexPath = require.toUrl "../katex/katex.min.css"
        linkKatex = document.createElement "link"
        linkKatex.setAttribute "rel", "stylesheet"
        linkKatex.setAttribute "href", cssKatexPath
        $("head")[0].appendChild linkKatex
        # document.getElementsByTagName('head')[0].appendChild linkKatex

        # Adding CSS for demo formula
        cssDemoPath = require.toUrl "./katex-demo.css"
        linkDemo = document.createElement "link"
        linkDemo.setAttribute "rel", "stylesheet"
        linkDemo.setAttribute "href", cssDemoPath
        $("head")[0].appendChild linkDemo
        document.getElementsByTagName('head')[0].appendChild linkDemo

        # Adding DOM element to place formula into
        span = document.createElement "span"
        span.setAttribute "id", "formula"
        $("body")[0].appendChild span
        document.getElementsByTagName('body')[0].appendChild span

        katex = require "ace/ext/katex/katex"

        # Drawing the sample formula in created element
        formulaString = "e^{i \\pi} + 1 = 0"
        katex.render formulaString, span
