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
var TextMode = require("./text").Mode;
var Tokenizer = require("../tokenizer").Tokenizer;
var LatexHighlightRules = require("../ext/papeeria/papeeria_latex_highlight_rules").PapeeriaLatexHighlightRules;
var LatexFoldMode = require("./folding/latex").FoldMode;
var LatexBehaviour = require("../../ace/ext/papeeria/latex_behaviour").LatexBehaviour;
var Range = require("../range").Range;
var WorkerClient = require("../worker/worker_client").WorkerClient;

var Mode = function() {
    this.HighlightRules = LatexHighlightRules;
    this.foldingRules = new LatexFoldMode();
};
oop.inherits(Mode, TextMode);


(function() {
    this.lineCommentStart = "%";
    this.$behaviour = new LatexBehaviour()

    var myDiscussionsCallbacks = {
        onSuccess: null
    };

    this.createWorker = function(session) {
        var worker = new WorkerClient(["ace"], "ace/mode/latex_worker", "LatexWorker");
        worker.attachToDocument(session.getDocument());

        worker.on("discussionsSettingsUpdateSuccess", function(result) {
            myDiscussionsCallbacks.onSuccess();
        });

        worker.on("discussions", function(discussions) {
            if (myDiscussionsCallbacks.onSuccess != null) {
                myDiscussionsCallbacks.onSuccess({
                  discussions: discussions,
                  lineCommentSymbol: this.lineCommentStart
                });
            }
        }.bind(this));

        var onChangeDiscussions = function(data) {
            myDiscussionsCallbacks = {
                onSuccess: data.onSuccess
            };
            worker.call("changeDiscussionsOptions", [{
                enabled: data.enabled,
                lineCommentSymbol: this.lineCommentStart
            }]);
        }.bind(this);

        worker.on("terminate", function() {
            session.off("changeDiscussionsSettings", onChangeDiscussions);
        });
        session.on("changeDiscussionsSettings", onChangeDiscussions);

        this.setupSpellchecker(worker, session);

        return worker;
    };

}).call(Mode.prototype);

exports.Mode = Mode;

});
