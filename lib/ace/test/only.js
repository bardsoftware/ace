"use strict";

require("amd-loader");
var test = require("asyncjs").test;

var path;
var warn = false;
for (var i = 2; i < process.argv.length; ++i) {
    if (process.argv[i] == "-W") {
        warn = true;
    } else {
        path = process.argv[i];
    }
}
if (!warn) {
    console.warn = function() {};
}
test.testcase(require(path)).exec();
