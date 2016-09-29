define(function(require, exports, module) {
    var TexCompleter = require("./papeeria/tex_completer");
    var BracketMatcher = require("./papeeria/highlighter");
    var KatexPreviewer = require("./papeeria/katex-previewer");
    module.exports.TexCompleter = TexCompleter;
    module.exports.KatexPreviewer = KatexPreviewer;
    module.exports.BracketMatcher = BracketMatcher;
});
