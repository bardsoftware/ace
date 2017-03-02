define(function(require, exports, module) {
"use strict";


var TextParser = exports.TextParser = function(bgTokenizer) {
    this.myErrors = [];
    this.myTokenizer = bgTokenizer;
};

(function(){
    this.setSpellingCheckDictionary = function(typos, alphabet) {
        this.myTypos = typos;
        this.myAlphabet = alphabet;
    };

    /**
     * Find misspelled words in the document
     */
    this.go = function(doc) {
        if (this.myTypos === null) {
            return;
        }

        var lines = doc.getAllLines();
        this.myErrors = [];

        for (var row = 0, linesLength = lines.length; row < linesLength; row++) {
            var line = lines[row];
            var tokens = this.myTokenizer.getTokens(row);

            var column = 0;
            var tokenLength = tokens.length;
            for (var j = 0; j < tokenLength; j++) {
                var token = tokens[j];

                var tokenColumn = line.slice(column).indexOf(token.value);
                if (tokenColumn != -1) {
                    column += tokenColumn;
                }
                parseRowForSpellcheck.call(this, token.value, row, column);
            }
        }
    }

    /**
     * Split the text string to words, detect and collect misspelled words
     * @param tokenValue:string  input string to be splitted to words
     * @param row:number         row position of the incoming token in document
     * @param column:number      column position of the incoming token in document
     */
    function parseRowForSpellcheck(tokenValue, row, column) {
        var words = this.splitTextToWords(tokenValue, row, column);
        for (var i = 0, wordsLength = words.length; i < wordsLength; i++) {
            if (typeof this.myTypos[words[i].value] !== 'undefined') {
                this.myErrors.push({
                    row: words[i].row,
                    column: words[i].column,
                    text: "grammar error",
                    type: "error",
                    raw: words[i].value
                });
            }
        }
    }

    this.splitTextToWords = function(text, row, column) {
        var regex = new RegExp('^[' + this.myAlphabet + ']+', 'i');
        var words = [];
        var pos = 0;
        while (pos < text.length) {
            var match = regex.exec(text.substr(pos));
            if (match) {
                words.push({
                    value: match[0],
                    row: row,
                    column: column + pos
                });
                pos += match[0].length;
            } else {
                pos++;
            }
        }
        return words;
    };

    this.getErrors = function() {
        return this.myErrors;
    };

}).call(TextParser.prototype);

});
