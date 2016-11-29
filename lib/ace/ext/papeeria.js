define(function(require, exports, module) {
    var BracketMather = require("./papeeria/highlighter");
    var KatexPreviewer = require("./papeeria/katex-previewer");
    var Spellchecker = require("./papeeria/spellchecker");
    var SpellcheckerPopup = require("./papeeria/spellchecker_popup");
    var TexCompleter = require("./papeeria/tex_completer");
    module.exports.BracketMather = BracketMather;
    module.exports.KatexPreviewer = KatexPreviewer;
    module.exports.Spellchecker = Spellchecker;
    module.exports.SpellcheckerPopup = SpellcheckerPopup;
    module.exports.TexCompleter = TexCompleter;
});
