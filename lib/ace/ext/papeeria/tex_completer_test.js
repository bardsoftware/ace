// Copyright (C) 2017 BarD Software s.r.o
// Author: Dmitry Barashev
if (typeof process !== "undefined") {
    require("amd-loader");
}

define(function(require, exports, module) {
    var assert = require("ace/test/assertions");
    var TexCompleter = require("ace/ext/papeeria/tex_completer");

    module.exports = {
        "test: references completer": function() {
            texCompleter = new TexCompleter();
            texCompleter.refCache.getJson = function(text, callback) {
              callback(JSON.parse(text));
            };
            refJson = '[{"caption": "capt0", "type": "references"}, {"caption": "capt1", "type": "references"}]'
            texCompleter.refCache.getReferences(refJson, function(wtf, labels) {
              assert.ok(labels);
              assert.equal(2, labels.length);
              assert.equal("capt0", labels[0].name);
              assert.equal("capt0", labels[0].value);
              assert.equal("references", labels[0].meta);
              assert.equal("capt1", labels[1].name);
              assert.equal("capt1", labels[1].value);
              assert.equal("references", labels[1].meta);
            });
        },
    }
});
