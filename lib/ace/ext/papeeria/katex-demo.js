define(function(require, exports, module) {
    // Adding KaTeX CSS
    var cssKatexPath = require.toUrl("../katex/katex.min.css");
    var linkKatex = document.createElement("link");
    linkKatex.setAttribute("rel", "stylesheet");
    linkKatex.setAttribute("href", cssKatexPath);
    document.getElementsByTagName('head')[0].appendChild(linkKatex);

    // Adding CSS for demo formula
    var cssDemoPath = require.toUrl("./katex-demo.css");
    var linkDemo = document.createElement("link");
    linkDemo.setAttribute("rel", "stylesheet");
    linkDemo.setAttribute("href", cssDemoPath);
    document.getElementsByTagName('head')[0].appendChild(linkDemo);

    // Adding DOM element to place formula into
    var span = document.createElement("span");
    span.setAttribute("id", "formula");
    document.getElementsByTagName('body')[0].appendChild(span);

    var katex = require("ace/ext/katex/katex");

    // Drawing the sample formula in created element
    var formulaString = "e^{i \\pi} + 1 = 0";
    katex.render(formulaString, span);
});
