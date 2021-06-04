require("amd-loader");
var test = require("asyncjs").test;
console.warn = function() {};
test.walkTestCases(__dirname + "/..").exec();
