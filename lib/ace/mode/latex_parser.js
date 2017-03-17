define(function(require, exports, module) {
"use strict";


var oop = require("../lib/oop");
var TextParser = require("./text_parser").TextParser;


var getDiscussionCommentRegexp = function(lineCommentSymbol) {
    // Examples of discussion heading:
    //  * First discussion comment
    //      % * <foo@bar.com> 2015-01-12T00:17:27.829Z:
    //  * Reply
    //      % ^ <Display Name> 2015-01-12:
    //  * No datetime specified
    //      % * <foo@bar.com>:
    return new RegExp(
        "^" +
        "\\s*" + lineCommentSymbol +
        "\\s+" + "([\\*\\^])" + // type of discussion: * or ^
        "\\s+" + "<(.+)>" +     // author: email or display name in angle brackets
        "\\s*(.*?)\\s*" +       // datetime without leading/trailing spaces
        ":\\s*$"
    );
};
var getDiscussionTextRowRegexp = function(lineCommentSymbol) {
    return new RegExp(
        "^" +
        "\\s*" + lineCommentSymbol +
        "\\s*" + "(.*)" + // row with text without leading spaces
        "$"
    );
};

var LatexParser = exports.LatexParser = function(bgTokenizer) {
    TextParser.call(this, bgTokenizer);
    this.myDiscussions = [];
};

oop.inherits(LatexParser, TextParser);


(function(){
    /**
     * Parse the document
     * @param doc              document object
     * @param options: {
     *   spellcheck            true if we want spellcheck
     *   parseDiscussions      true if we want get text comments,
     *   lineCommentSymbol     e.g. '%' for tex documents
     * }
     */
    this.go = function(doc, options) {
        if (!options) {
            throw Error("IllegalArgumentException: options can't be null");
        }
        var doSpellcheck = options.spellcheck;
        var doGetDiscussions = options.parseDiscussions;
        var lineCommentSymbol = options.lineCommentSymbol;

        if (doSpellcheck && this.myTypos === null) {
            // there may be a situation when this method runs before the dictionary
            // loaded, so don't throw an exception, just don't spellcheck
            doSpellcheck = false;
        }
        if (!doSpellcheck && !doGetDiscussions) {
            // there is nothing to do
            return;
        }

        var lines = doc.getAllLines();

        this.myErrors = [];
        this.myDiscussions = [];
        this.myLastReadDiscussionComment = null;

        for (var row = 0, linesLength = lines.length; row < linesLength; row++) {
            var line = lines[row];
            var tokens = this.myTokenizer.getTokens(row);

            var column = 0;
            var tokenLength = tokens.length;
            // stop parse discussion on empty line
            // otherwise we will add a regular comment to the discussion:
            //     % DISCUSSION
            //     EMPTY_LINE
            //     % REGULAR COMMENT
            if (tokenLength === 0) {
              doGetDiscussions && this.saveLastReadDiscussionComment();
            }
            for (var j = 0; j < tokenLength; j++) {
                var token = tokens[j];

                var tokenColumn = line.slice(column).indexOf(token.value);
                if (tokenColumn != -1) {
                    column += tokenColumn;
                }

                switch(token.type) {
                    case "comment":
                        if (tokenLength === 1 && doGetDiscussions) {
                            // parse discussions only when the whole line tokenized as a comment
                            this.parseRowForDiscussions(token.value, row, lineCommentSymbol);
                        }
                        doSpellcheck && this.parseRowForSpellcheck(token.value, row, column);
                        break;
                    case "text":
                        doGetDiscussions && this.saveLastReadDiscussionComment();
                        doSpellcheck && this.parseRowForSpellcheck(token.value, row, column);
                        break;
                    default:
                        doGetDiscussions && this.saveLastReadDiscussionComment();
                        // skip tokens we don't want to parse
                        break;
                }
            }
        }
        // save last read comment in case of the document ends with this comment
        doGetDiscussions && this.saveLastReadDiscussionComment();
    }


    /**
     * Parse the text line for discussion (heading or body)
     * If incoming text line is discussion heading, next calls of this function will
     * parse the discussion body
     * @param line:string        latex comment started with %
     * @param row:number         row number of this line in document
     * @param lineCommentSymbol  e.g. '%' for tex documents
     */
    this.parseRowForDiscussions = function(line, row, lineCommentSymbol) {
        // comment format: % TYPE <AUTHOR> DATETIME:
        // {
        //     TYPE: '*' for the first comment in discussion, '^' for replies
        //     AUTHOR: any string, e.g. email
        //     DATETIME: any string
        // }
        var matchComment = line.match(getDiscussionCommentRegexp(lineCommentSymbol));
        if (matchComment) {
            // if we met a new discussion title, stop reading body of the previous discussion
            // and start a new one
            this.saveLastReadDiscussionComment();
            this.myLastReadDiscussionComment = {
                type: matchComment[1],
                author: matchComment[2],
                datetime: matchComment[3],
                row: row,
                textLines: [],
                replies: []
            };
        } else if (this.myLastReadDiscussionComment !== null) {
            var matchTextRow = line.match(getDiscussionTextRowRegexp(lineCommentSymbol));
            if (matchTextRow) {
                this.myLastReadDiscussionComment.textLines.push(matchTextRow[1]);
            }
        }
    }

    this.saveLastReadDiscussionComment = function() {
        if (this.myLastReadDiscussionComment === null) {
            // nothing to save
            return;
        }
        switch (this.myLastReadDiscussionComment.type) {
            case '*':
                this.myDiscussions.push(this.myLastReadDiscussionComment);
                break;
            case '^':
                var lastIdx = this.myDiscussions.length - 1;
                if (this.myDiscussions[lastIdx] !== undefined) {
                    this.myDiscussions[lastIdx].replies.push(this.myLastReadDiscussionComment);
                }
                break;
            default:
                throw Error("Unsupported discussion type: " + this.myLastReadDiscussionComment.type);
        }
        this.myLastReadDiscussionComment = null;
    }

    this.getDiscussions = function() {
        return this.myDiscussions;
    };

}).call(LatexParser.prototype);

});
