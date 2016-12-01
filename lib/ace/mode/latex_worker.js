define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Mirror = require("../worker/mirror").Mirror;
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var LatexParser = require("./latex_parser").LatexParser;
var LatexHighlightRules = require("./latex_highlight_rules").LatexHighlightRules;

var WORKER_TIMEOUT_MS = 20;
var STATE_COMPLETE = 4;
var HTTP_REQUEST_STATUS = {
    OK: 200,
    NOT_MODIFIED: 304
};

var get = function(url, onSuccessCallback, onErrorCallback) {
    var xhr = new XMLHttpRequest();
    xhr.open("GET", url, true);
    xhr.onreadystatechange = function () {
        if (xhr.readyState === STATE_COMPLETE) {
            if (xhr.status === HTTP_REQUEST_STATUS.OK || xhr.status === HTTP_REQUEST_STATUS.NOT_MODIFIED) {
                onSuccessCallback({
                    content: xhr.responseText
                });
            } else {
                onErrorCallback({
                    status: xhr.status,
                    content: xhr.statusText
                });
            }
        }
    };
    xhr.send(null);
};

var makeSet = function(array) {
    var tmp = {};
    for (var i = 0; i < array.length; i++) {
        tmp[array[i]] = true;
    }
    return tmp;
};

var LatexWorker = exports.LatexWorker = function(sender) {
    Mirror.call(this, sender);
    this.setTimeout(WORKER_TIMEOUT_MS);
    this.mySpellingCheckOptions = {};
    this.myDiscussionsOptions = {};
    this.myTypos = {};
    var highlighter = new LatexHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new LatexParser(this.myBgTokenizer);
};

oop.inherits(LatexWorker, Mirror);

(function() {

    this.updateSpellcheckingTypos = function(newTypos) {
        this.myTypos = makeSet(newTypos);
        this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
    };

    this.changeSpellingCheckOptions = function(newOptions) {
        oop.mixin(this.mySpellingCheckOptions, newOptions);

        if (newOptions.enabled) {
            this.sender.emit("settingsUpdateSuccess", []);
            this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
        }
    };

    this.changeDiscussionsOptions = function(newOptions) {
        this.myDiscussionsOptions = newOptions;
        this.sender.emit("discussionsSettingsUpdateSuccess", []);
        this.deferredUpdate.schedule(WORKER_TIMEOUT_MS);
    };

    this.onUpdate = function() {
        var doSpellcheck = false,
            doGetDiscussions = false;

        if (this.doc.getValue()) {
            doGetDiscussions = this.myDiscussionsOptions.enabled;

            if (this.mySpellingCheckOptions.enabled) {
                doSpellcheck = true;
                this.myParser.setSpellingCheckDictionary(this.myTypos, this.mySpellingCheckOptions.alphabet);
            } else {
                doSpellcheck = false;
                this.sender.emit("spellcheck", []);
            }

            this.myBgTokenizer.setDocument(this.doc);
            this.myParser.go(this.doc, {
                spellcheck: doSpellcheck,
                parseDiscussions: doGetDiscussions,
                lineCommentSymbol: this.myDiscussionsOptions.lineCommentSymbol
            });

            doSpellcheck && this.sender.emit("spellcheck", this.myParser.getErrors());
            doGetDiscussions && this.sender.emit("discussions", this.myParser.getDiscussions());
        }
    };

}).call(LatexWorker.prototype);

});
