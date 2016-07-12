// Generated by CoffeeScript 1.10.0
(function() {
  define(function(require, exports, module) {
    require("ace/ext/jquery");
    return $(document).ready(function() {
      var cssDemoPath, cssKatexPath, formulaString, katex, linkDemo, linkKatex, span;
      cssKatexPath = require.toUrl("../katex/katex.min.css");
      linkKatex = document.createElement("link");
      linkKatex.setAttribute("rel", "stylesheet");
      linkKatex.setAttribute("href", cssKatexPath);
      $("head")[0].appendChild(linkKatex);
      cssDemoPath = require.toUrl("./katex-demo.css");
      linkDemo = document.createElement("link");
      linkDemo.setAttribute("rel", "stylesheet");
      linkDemo.setAttribute("href", cssDemoPath);
      $("head")[0].appendChild(linkDemo);
      document.getElementsByTagName('head')[0].appendChild(linkDemo);
      span = document.createElement("span");
      span.setAttribute("id", "formula");
      $("body")[0].appendChild(span);
      document.getElementsByTagName('body')[0].appendChild(span);
      katex = require("ace/ext/katex/katex");
      formulaString = "e^{i \\pi} + 1 = 0";
      return katex.render(formulaString, span);
    });
  });

}).call(this);