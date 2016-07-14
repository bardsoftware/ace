define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;

var PapeeriaLatexHighlightRules = function() {  

    this.$rules = {
        "start" : [{
            // A comment. Tex comments start with % and go to 
            // the end of the line
            token : "comment",
            regex : "%.*$"
        }, {
            // A equation
            token : ["storage.type", "lparen", "variable.parameter", "rparen"],
            regex : "(\\\\(?:begin))({)(equation|equation\\\*)(})",
            next: "equation"
        }, {
                    // Documentclass and usepackage
            token : ["keyword", "lparen", "variable.parameter", "rparen", "lparen", "storage.type", "rparen"],
            regex : "(\\\\(?:documentclass|usepackage|input))(?:(\\[)([^\\]]*)(\\]))?({)([^}]*)(})"
        }, {
            // A label
            token : ["keyword","lparen", "variable.parameter", "rparen"],
            regex : "(\\\\(?:label|v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
        }, {
            // A block
            token : ["storage.type", "lparen", "variable.parameter", "rparen"],
            regex : "(\\\\(?:begin|end))({)(\\w*)(})"
        }, {
            // A tex command e.g. \foo
            token : "storage.type",
            regex : "\\\\[a-zA-Z]+"
        }, {
            // Curly and square braces
            token : "lparen",
            regex : "[[({]"
        }, {
            // Curly and square braces
            token : "rparen",
            regex : "[\\])}]"
        }, {
            // Escaped character (including new line)
            token : "constant.character.escape",
            regex : "\\\\[^a-zA-Z]?"
        }],
        "equation" : [{
            token : ["storage.type", "lparen", "variable.parameter", "rparen"],
            regex : "(\\\\(?:end))({)(equation|equation\\\*)(})",
            next: "start"
        }, {
            token : "comment",
            regex : "%.*$"
        }, {
            token : "constant.character.escape",
            regex : "\\\\(?:[^a-zA-Z]|[a-zA-Z]+)"
        }]
    };
};
oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules);

exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules;

});
