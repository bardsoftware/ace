"use strict";

require("amd-loader");
var test = require("asyncjs").test;
var path = process.argv[2];
console.warn = function() {};
test.testcase(require("../" + path)).exec();
