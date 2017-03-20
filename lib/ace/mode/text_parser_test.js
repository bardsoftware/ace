/* ***** BEGIN LICENSE BLOCK *****
 * BSD 3-Clause License
 *
 * Copyright (c) 2017, BarD Software s.r.o
 * All rights reserved.
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are met:
 *     * Redistributions of source code must retain the above copyright
 *       notice, this list of conditions and the following disclaimer.
 *
 *     * Redistributions in binary form must reproduce the above copyright
 *       notice, this list of conditions and the following disclaimer in the
 *       documentation and/or other materials provided with the distribution.
 *
 *     * Neither the name of Ajax.org B.V. nor the
 *       names of its contributors may be used to endorse or promote products
 *       derived from this software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
 * ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL AJAX.ORG B.V. BE LIABLE FOR ANY
 * DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
 * (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
 * LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
 * ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
 * SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 * ***** END LICENSE BLOCK ***** */

if (typeof process !== "undefined") {
  require("amd-loader");
}

define(function(require, exports, module) {
"use strict";

var TextParser = require("./text_parser").TextParser;
var assert = require("../test/assertions");


module.exports = {
  setUp : function() {
    this.parser = new TextParser(null);
  },

  "test: splitTextToWords" : function() {
    this.parser.setSpellingCheckDictionary({}, "0123456789");
    var row = 15;

    assert.deepEqual([
      {value: "abcd", row: row, column: 0},
      {value: "cde", row: row, column: 6},
      {value: "cdf-//\\ d", row: row, column: 11}
    ], this.parser.splitTextToWords("abcd12cde32cdf-//\\ d2", row, 0));

    assert.deepEqual(
      [{value: "abcd", row: row, column: 11}],
      this.parser.splitTextToWords("11abcd122", row, 9));
  },

  "test: parseRowForSpellcheck": function() {
    assert.deepEqual({}, this.parser.getErrors(), "no error yet");
    var row = 8;

    this.parser.setSpellingCheckDictionary({}, "123");
    this.parser.setSpellingCheckDictionary({"abc": true, "bcde": true}, "\\s");


    this.parser.parseRowForSpellcheck("abc dewdew rfer bcdef abcde bcde", row, 0);

    var constructTypo = function(value, column) {
      return {
        text: "grammar error",
        type: "error",
        row: row,
        column: column,
        raw: value
      };
    }

    assert.deepEqual([
        constructTypo("abc", 0),
        constructTypo("bcde", 28)
      ], this.parser.getErrors());
  },
};

});

if (typeof module !== "undefined" && module === require.main) {
  require("asyncjs").test.testcase(module.exports).exec()
}
