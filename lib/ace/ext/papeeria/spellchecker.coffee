define((require, exports, module) ->
    # This will be removed and replaced with real data from server
    # BTW, this is kinda template for data to send from server, eh?
    TEST_JSON_TYPOS = [
        {
            word: "blablabla",
            corrections: [
                "blah-blah",
                "blabber",
                "blabbed",
                "salable"
            ]
        }
    ]


    # SpellChecker is a class that by now provides highlighting of words that takes from JSON.
    class SpellChecker
        # By now it's just a stub, but I guess this function will take data from server somehow in future.
        # TODO
        # @return {Object} JSON-list of incorrect words.
        getJson: =>
            return TEST_JSON_TYPOS

        # Function checks whether token is in JSON incorrect words list.
        # @param {String} token Token to check.
        # @return {Boolean} False if token is in list, true otherwise.
        check: (token) =>
            wordsList = @getJson()
            for item in wordsList
                if token == item.word
                    console.log(token, item.corrections)    # Let's just put this out to console for now
                    return false
            return true


    exports.SpellChecker = SpellChecker
    return
)