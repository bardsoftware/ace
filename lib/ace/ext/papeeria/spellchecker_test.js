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
    require("../../test/mockdom");
}

define(function(require, exports, module) {
"use strict";

var Spellchecker = require("./spellchecker");
var EditSession = require("ace/edit_session").EditSession;
var Editor = require("ace/editor").Editor;
var MockRenderer = require("ace/test/mockrenderer").MockRenderer;
var assert = require("../../test/assertions");

var typosFetched = 0;
var suggestionsFetched = 0;

function createFetchTypos(typos) {
  return function(text, callback) {
    callback.apply(this, [typos]);
    typosFetched++;
  }
}

function fetchSuggestions(token, lang, callback) {
  callback.apply();
  suggestionsFetched++;
}


module.exports = {

  setUp: function() {
    this.editor = new Editor(new MockRenderer(), new EditSession(["some text"]));
    Spellchecker.setup(this.editor);
    this.spellchecker = Spellchecker.getInstance();
  },

  "test: onHashUpdated": function() {
    this.spellchecker.onSettingsUpdated(
      {punctuation: " ", isEnabled: true, tag: "en_US"},
      createFetchTypos([]),
      fetchSuggestions
    );

    typosFetched = 0;

    this.spellchecker.onHashUpdated("123");
    assert.equal(1, typosFetched, "new hash, typos should be fetched");

    this.spellchecker.onHashUpdated("123");
    assert.equal(1, typosFetched, "same hash, typos should not be fetched");

    this.spellchecker.onHashUpdated("321");
    assert.equal(2, typosFetched, "new hash, typos should be fetched");

    this.spellchecker.onHashUpdated("123");
    assert.equal(3, typosFetched, "new hash, typos should be fetched");
  },

  "test: onSettingsUpdated": function() {
    typosFetched = 0;

    this.spellchecker.onSettingsUpdated(
      {punctuation: "123", isEnabled: true, tag: "ru_RU"},
      createFetchTypos([]),
      fetchSuggestions
    );

    assert.equal(1, typosFetched, "onSettingsUpdated should fetch new typos");
  },

  "test: isWordTypo": function() {
    assert.equal(false,  this.spellchecker.isWordTypo("abc"));

    this.spellchecker.onSettingsUpdated(
      {punctuation: "123", isEnabled: true, tag: "ru_RU"},
      createFetchTypos(["abc", "foo", "bar"]),
      fetchSuggestions
    );

    assert.equal(true,  this.spellchecker.isWordTypo("abc"));
    assert.equal(true,  this.spellchecker.isWordTypo("foo"));
    assert.equal(true,  this.spellchecker.isWordTypo("bar"));
    assert.equal(false, this.spellchecker.isWordTypo("foobar"));
    assert.equal(false, this.spellchecker.isWordTypo("bca"));
    assert.equal(false, this.spellchecker.isWordTypo("a"));
    assert.equal(false, this.spellchecker.isWordTypo("o"));
  },

  "test: getCorrections": function() {
    suggestionsFetched = 0;
    this.spellchecker.getCorrections("abc", function() {});
    assert.equal(1, suggestionsFetched);
  }
};

});

if (typeof module !== "undefined" && module === require.main) {
  require("asyncjs").test.testcase(module.exports).exec()
}
