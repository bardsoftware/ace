define(function(require, exports, module) {
    var BracketMatcher = require("./papeeria/highlighter");
    var KatexPreviewer = require("./papeeria/katex-previewer");
    var Spellchecker = require("./papeeria/spellchecker");
    var SpellcheckerPopup = require("./papeeria/spellchecker_popup");
    var TexCompleter = require("./papeeria/tex_completer");
    module.exports.BracketMatcher = BracketMatcher;
    module.exports.KatexPreviewer = KatexPreviewer;
    module.exports.Spellchecker = Spellchecker;
    module.exports.SpellcheckerPopup = SpellcheckerPopup;
    module.exports.TexCompleter = TexCompleter;
});
