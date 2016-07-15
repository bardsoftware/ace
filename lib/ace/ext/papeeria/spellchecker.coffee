define((require, exports, module) ->
    # SpellChecker is a class that by now provides only numbers highlighting,
    # but it will provide a hunspell spellchecking someday.
    class SpellChecker
        constructor: ->

        # Function checks whether token is numeric.
        # @param {String} token Token to check.
        # @return {Boolean} True if token is numeric, false otherwise.
        check: (token) =>
            return !NUMERIC_REGEXP.test(token)


    exports.SpellChecker = SpellChecker
    return
)


# Regexp to check if token is a number
NUMERIC_REGEXP = /^\d+$/