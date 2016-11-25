define(function(require, exports, module) {
    exports.getCompletions = function (editor, session, pos, prefix, callback) {
        var wordList = ["\\item"];

        callback(null, wordList.map(function (word) {
            return {
                caption: word,
                value: word,
                meta: "TEX"
            };
        }));
    };
});
