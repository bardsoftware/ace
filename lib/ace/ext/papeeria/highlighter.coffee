foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
    ourOffscreenTextDisplay = null
    Range = require("ace/range").Range
    TokenIterator = require("ace/token_iterator").TokenIterator
    clearCurrentHighlight = (editor, session, placeholderRange = null) ->
        if session.$bracketMatchHighlight || session.$bracketMismatchHighlight
            session.removeMarker(session.$bracketMatchHighlight)
            session.removeMarker(session.$bracketMismatchHighlight)
            session.$bracketMatchHighlight = null
            session.$bracketMismatchHighlight = null
            session.$highlightRange = placeholderRange
            toggleSurroundingBracketsPopup(editor)

    highlightBrackets = (editor, pos) ->
        session = editor.getSession()
        clearCurrentHighlight(editor, session)

        pos ?= findSurroundingBrackets(session, editor.getCursorPosition())
        if !pos.mismatch
            range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
            session.$bracketMatchHighlight = session.addMarker(range, "ace_selection ace_bracket_match_range", "text")
        else
            if pos.left && pos.right
                range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
                session.$bracketMismatchHighlight = session.addMarker(range, "ace_error-marker", "text")
            if pos.left && !pos.right
                rangeLeft = new Range(pos.left.row, pos.left.column, Infinity, Infinity)
                session.$bracketMismatchHighlight = session.addMarker(rangeLeft, "ace_error-marker", "text")
            if pos.right && !pos.left
                rangeRight = new Range(0, 0, pos.right.row, pos.right.column + 1)
                session.$bracketMismatchHighlight = session.addMarker(rangeRight, "ace_error-marker", "text")
        session.$highlightRange = pos
        toggleSurroundingBracketsPopup(editor, pos.left, pos.right)
        return

    newFakeToken = (pos) ->
        token: ""
        row: pos.row
        column: pos.column
        contains: (pos) ->
            return @row == pos.row && @column == pos.column


    newFilteringIterator = (openingBracket, closingBracket, session, pos, isForward) ->
        tokenIterator = new TokenIterator(session, pos.row, pos.column)
        token = tokenIterator.getCurrentToken()
        token ?= if isForward then tokenIterator.stepForward() else tokenIterator.stepBackward()
        if not token?
            return null
        typeRe = /(\.?.paren)+/
        result = session.$newFilteringIterator(
            tokenIterator,
            (filteringIterator) ->
                token = tokenIterator.getCurrentToken()
                while token and !typeRe.test(token.type)
                    token = if isForward then tokenIterator.stepForward() else tokenIterator.stepBackward()
                if token?
                    filteringIterator.$updateCurrent()
                    if isForward then tokenIterator.stepForward() else tokenIterator.stepBackward()
                    return true
                else
                    filteringIterator.$current = null
                    return false
        )
        if isForward
            if not result.next() then return null
        else
            result.$updateCurrent()
            # if Tokeniterator is created from the cursor position, its first token
            # will be the one which immediately precedes the position (its start+length>=position)
            # Code in session.$findOpeningBracket effectively skips this token, so if cursor is positioned immediately
            # after closing bracket } then this bracket will be ignored and ultimately findOpeningBracket
            # will return wrong result (e.g. for this text: {\foo}_  it will return { as the result)
            # To fix it we initialize filtering iterator with a fake empty token.
            current = result.current()
            if !typeRe.test(token.type)
                result.next()
            else
                # When we either at a single bracket or in the first position of a multi-bracket token like =>}<=}} (zero } is a cursor position)
                if current.token.value.length == 1 or current.column == pos.column
                    # We don't want to swallow the bracket when cursor is right behind" {foo}_
                    if current.contains(pos) and current.column < pos.column
                        result.$current = newFakeToken(pos)
                        return result
                    # But if it is at the bracket position then we want to proceed to the next token
                    result.next()
                else
                    # Other wise, we're somewhere in the middle of a multi-bracket token: }=>{<=
                    # We want to search for brackets in the prefix before the cursor, and immediately proceed to the
                    # next token afterwards. For this purpose we position token iterator to the next value and fake the current value,
                    # so that findOpeningBracket will think that cursor is placed after the prefix of the current token.
                    result.next()
                    fakeToken =
                        token: {
                            value: current.token.value.substring(0, pos.column - current.column)
                            type: current.token.type
                        }
                        row: current.row
                        column: current.column
                        contains: -> false
                    result.$current = fakeToken
                    return result

        return if result.current()? then result else null

    findSurroundingBrackets = (session, pos) ->
        allBrackets =
            left: [
                session.$findOpeningBracket('}', pos, newFilteringIterator('{', '}', session, pos, false))
                session.$findOpeningBracket(']', pos, newFilteringIterator('[', ']', session, pos, false))
                session.$findOpeningBracket(')', pos, newFilteringIterator('(', ')', session, pos, false))
            ]
            right: [
                session.$findClosingBracket('{', pos, newFilteringIterator('{', '}', session, pos, true))
                session.$findClosingBracket('[', pos, newFilteringIterator('[', ']', session, pos, true))
                session.$findClosingBracket('(', pos, newFilteringIterator('(', ')',  session, pos, true))
            ]
        leftNearest = null
        rightNearest = null
        key = 0
        while key < allBrackets.left.length
            leftCandidate = allBrackets.left[key]
            rightCandidate = allBrackets.right[key]
            if !leftNearest
                leftNearest = leftCandidate
            if !rightNearest
                rightNearest = rightCandidate
            if leftCandidate
                if leftNearest.row <= leftCandidate.row
                    if leftNearest.row == leftCandidate.row
                        if leftNearest.column < leftCandidate.column
                            leftNearest = leftCandidate
                    else
                        leftNearest = leftCandidate
            if rightCandidate
                if rightNearest.row >= rightCandidate.row
                    if rightNearest.row == rightCandidate.row
                        if rightNearest.column > rightCandidate.column
                            rightNearest = rightCandidate
                    else
                        rightNearest = rightCandidate
            key++

        result =
            equalPos: (pos1, pos2) ->
                if pos1? and pos2?
                    return pos1.row == pos2.row and pos1.column == pos2.column
                else
                    return not(pos1? or pos2?)
            left: leftNearest
            right: rightNearest
            mismatch: true
            equals: (object) ->
                if object?
                    return @mismatch == object.mismatch and @equalPos(@left, object.left) and @equalPos(@right, object.right)
                return false
            isDefined: -> @left? or @right?

        if result.left && result.right
            expectedRightBracket = session.$brackets[session.getLine(result.left.row).charAt(result.left.column)]
            rightBracket = session.getLine(result.right.row).charAt(result.right.column)
            if expectedRightBracket == rightBracket
                result.mismatch = false
        result.start = result.left
        result.end = result.right
        return result

    toggleSurroundingBracketsPopup = (editor, left, right) ->
        if left?
            left = {row: left.row + 1, column: left.column+ 1}
        if right?
            right = {row: right.row + 1, column: right.column + 1}
        if not left? and not right?
            ourOffscreenTextDisplay?(editor)
        else
            ourOffscreenTextDisplay?(editor, left, right)

    init = (ace, editor, bindKey, offscreenTextDisplay) ->
        ourOffscreenTextDisplay = offscreenTextDisplay
        session = editor.getSession()
        keyboardHandler =
            name: 'highlightBrackets'
            bindKey: bindKey
            exec: (editor)  ->
                session = editor.getSession()
                if session.$highlightRange
                    clearCurrentHighlight(editor, session)
                else
                    highlightBrackets(editor)
            readOnly: true


        editor.commands.addCommand(keyboardHandler)

        onEditorChange = ->
            currentRange = session.$highlightRange
            if currentRange?
                candidateRange = findSurroundingBrackets(session, editor.getCursorPosition())
                if !currentRange.equals(candidateRange)
                    if candidateRange?.isDefined()
                        highlightBrackets(editor, candidateRange)
                    else
                        clearCurrentHighlight(editor, session, candidateRange)
                else
                    toggleSurroundingBracketsPopup(editor, currentRange.left, currentRange.right)
            return

        session.getSelection().on("changeCursor", onEditorChange)
        editor.on("change", onEditorChange)
        editor.getSession().on("changeScrollTop", onEditorChange)

        return

    return {
        highlightBrackets: highlightBrackets
        findSurroundingBrackets: findSurroundingBrackets
        init: init
    }
)
