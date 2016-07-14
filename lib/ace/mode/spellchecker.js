define(function(require, exports, module) {
"use strict";

/**
 * SpellChecker by now provides numbers highlighting but it will provide
 * a hunspell spellchecking someday.
 *
 * SpellChecker constructor:
 * @returns {SpellChecker} A SpellChecker object.
 */
var SpellChecker = function () {
    return this;
};

/**
 * Checks whether a token is numeric.
 *
 * @param {String} token Token to check.
 * @returns {Boolean} True if token is numeric, false otherwise.
 */
SpellChecker.prototype.check = function (token) {
    var trimmedWord = token.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    var NumericRegExp = /^\d+$/;

    return !NumericRegExp.test(trimmedWord);
};
    
exports.SpellChecker = SpellChecker;

});

