define(function(require, exports, module) {
"use strict";
var Typo = require("../lib/typo").Typo;

/**
 * NumericTypo derives Typo, JavaScript implementation of a spellchecker using hunspell-style dictionaries.
 * @see https://github.com/cfinke/Typo.js/
 *
 * NumericTypo constructor:
 * @returns {NumericTypo} A NumericTypo object.
 */
var NumericTypo = function () {
    Typo.call(this);
    return this;
};

/*
 * Copy Typo prototype for inheritance with the prototype chain
 * Can't just take Typo.prototype.__proto__ because of IE
 */
NumericTypo.prototype = Object.create(Typo.prototype);

/**
 * Checks whether a token is numeric (overrides Typo.check()).
 *
 * @param {String} token Token to check.
 * @returns {Boolean}
 */
NumericTypo.prototype.check = function (token) {
    var trimmedWord = token.replace(/^\s\s*/, '').replace(/\s\s*$/, '');
    var NumericRegExp = /^\d+$/;

    return !NumericRegExp.test(trimmedWord);
};
    
exports.NumericTypo = NumericTypo;

});

