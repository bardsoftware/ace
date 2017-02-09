/* ***** BEGIN LICENSE BLOCK *****
 * BSD 3-Clause License
 *
 * Copyright (c) 2017, BarD Software s.r.o
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright notice, this
 *       list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright notice,
 *       this list of conditions and the following disclaimer in the documentation
 *       and/or other materials provided with the distribution.
 *
 *     * Neither the name of the copyright holder nor the names of its
 *       contributors may be used to endorse or promote products derived from
 *       this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
 * AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 * IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
 * DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
 * SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
 * CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
 * OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK *****
 *
 * Author khazhoyan.arsen@gmail.com
 *
 */

define(function(require, exports, module) {
"use strict";

var oop = require("../lib/oop");
var Tokenizer = require("../tokenizer").Tokenizer;
var BackgroundTokenizer = require("../background_tokenizer").BackgroundTokenizer;

var PapeeriaWorker = require("./papeeria_worker").PapeeriaWorker;
var TextParser = require("./text_parser").TextParser;
var MarkdownHighlightRules = require("./markdown_highlight_rules").MarkdownHighlightRules;


var MarkdownWorker = exports.MarkdownWorker = function(sender) {
    PapeeriaWorker.call(this, sender);
    var highlighter = new MarkdownHighlightRules();
    this.myBgTokenizer = new BackgroundTokenizer(new Tokenizer(highlighter.getRules()));
    this.myBgTokenizer.setDocument(this.doc);
    this.myBgTokenizer.start(0);
    this.myParser = new TextParser(this.myBgTokenizer);
};

oop.inherits(MarkdownWorker, PapeeriaWorker);

});
