define((require, exports, module) ->
    # This will be removed and replaced with real data from server
    # BTW, this is kinda template for data to send from server, eh?
    #
    # Note: I modified the structure of json, because I thought, maybe
    # json mapping would be faster than searching for token in a loop?
    TEST_JSON_TYPOS = {
        "blablabla": [
            "blah-blah",
            "blabber",
            "blabbed",
            "salable"
        ]
    }

    # Class by now provides highlighting of words that takes from JSON.
    exports.SpellChecker = class SpellChecker
        # By now it's just a stub, but I guess this function will take data from server somehow in future.
        # TODO
        # @return {Object} JSON-list of incorrect words.
        getJson: =>
            return TEST_JSON_TYPOS

        # Check whether token is in JSON incorrect words list.
        # @param {String} token: Token to check.
        # @return {Boolean} False if token is in list, true otherwise.
        check: (token) =>
            correctionsList = @getJson()
            # New json structure makes it possible to search for token just like this
            return !correctionsList[token]

    # Implements some routines to show popup for spellchecker (to choose a proper substitution for a typo).
    # Also binds popup to an editor's shortcut.
    exports.setupSpellCheckerPopup = (editor) ->
        # Take corrections for current word and shows them in a popup.
        # @param {Array} corrections: popup has a setData function that takes some sort of
        # structure, it needs to be replicated so popup could show options for substitution.
        #
        # Some of this code is duplicated from autocomplete.js so it's just left as-is (by now?)
        showPopup = (options) =>
            AcePopup = require("ace/autocomplete/popup").AcePopup
            util = require("ace/autocomplete/util")
            HashHandler = require("ace/keyboard/hash_handler").HashHandler
            event = require("ace/lib/event")

            @popup = new AcePopup(document.body ? document.documentElement)
            @popup.setData(options)
            @popup.setTheme(editor.getTheme())
            @popup.setFontSize(editor.getFontSize())

            @commands = {
                # TODO
                # Doesn't work yet for some reason
                "Esc": (editor) ->
                    @popup.hide()
                    editor.keyBinding.removeKeyboardHandler(@keyboard);
                    console.log("esc")

            }
            @keyboard = new HashHandler()
            @keyboard.bindKeys(@commands)
            editor.keyBinding.addKeyboardHandler(@keyboard)

            # This part is like "magic, do not touch" thing. Was copied from autocomplete.js,
            # seems to set things up in a certain way so popup window opens under the cursor.
            renderer = editor.renderer
            lineHeight = renderer.layerConfig.lineHeight
            pos = renderer.$cursorLayer.getPixelPosition(this.base, true)
            pos.left -= @popup.getTextLeftOffset()
            rect = editor.container.getBoundingClientRect()
            pos.top += rect.top - renderer.layerConfig.offset
            pos.left += rect.left - editor.renderer.scrollLeft
            pos.left += renderer.gutterWidth

            @popup.show(pos, lineHeight)
            return

        # Convert an array of string to popup eligible structure.
        # @param {Array} corrections: array of strings with substitution options.
        # @returns {Array}: array of jsons, actually.
        convertCorrectionList = (corrections) ->
            options = []
            options.push({caption: item, value: item}) for item in corrections
            return options

        # Get the word under the cursor.
        # @returns {String}
        extractWord = ->
            session = editor.session
            row = editor.getCursorPosition().row
            col = editor.getCursorPosition().column
            wordPosition = session.getAWordRange(row, col)
            start = wordPosition.start.column
            end = wordPosition.end.column
            # getAWordRange returns start and end positions with a trailing
            # whitespace at the end (if there's a one), that's why replace is used
            return session.getLine(row).substring(start, end).replace(/\s\s*$/, '')

        # Check if current word is in corrections list.
        # Call showPopup if it's present, do nothing otherwise.
        tryPopup = ->
            word = extractWord()
            spellChecker = new SpellChecker()
            correctionsList = spellChecker.getJson()
            if correctionsList[word]
                showPopup(convertCorrectionList(correctionsList[word]))
            return

        # Bind a shortcut to tryPopup callback.
        editor.commands.addCommand({
            name: "test",
            bindKey: "Alt-Enter",
            exec: tryPopup
        })

        return

    return
)