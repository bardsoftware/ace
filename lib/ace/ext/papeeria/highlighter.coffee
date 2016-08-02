define([], ->
    TokenIterator = null
    Range = null
    clearCurrentHighlight = (session) ->
        if session.$bracketMatchHighlight || session.$bracketMismatchHighlight
            session.removeMarker(session.$bracketMatchHighlight)
            session.removeMarker(session.$bracketMismatchHighlight)
            session.$bracketMatchHighlight = null
            session.$bracketMismatchHighlight = null
            session.$highlightRange = null

    highlightBrackets = (editor, pos) ->
        session = editor.getSession()
        clearCurrentHighlight(session)

        pos ?= findSurroundingBrackets(editor)
        if !pos.mismatch
            range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
            session.$bracketMatchHighlight = session.addMarker(range, "ace_selection", "text")
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


    newFilteringIterator = (session, pos, isForward) ->
        tokenIterator = new TokenIterator(session, pos.row, pos.column)
        token = tokenIterator.getCurrentToken();
        token ?= tokenIterator.stepForward();
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
            # if Tokeniterator is created from the cursor position, its first token
            # will be the one which immediately precedes the position (its start+length>=position)
            # Code in session.$findOpeningBracket effectively skips this token, so if cursor is positioned immediately
            # after closing bracket } then this bracket will be ignored and ultimately findOpeningBracket
            # will return wrong result (e.g. for this text: {\foo}_  it will return { as the result)
            # To fix it we initialize filtering iterator with a fake empty token.
            result.$current = newFakeToken(pos)
        return result

    findSurroundingBrackets = (editor) ->
        session = editor.getSession();
        pos = editor.getCursorPosition()

        allBrackets =
            left: [
                session.$findOpeningBracket('}', pos, newFilteringIterator(session, pos, false))
                session.$findOpeningBracket(']', pos, newFilteringIterator(session, pos, false))
                session.$findOpeningBracket(')', pos, newFilteringIterator(session, pos, false))
            ]
            right: [
                session.$findClosingBracket('{', pos, newFilteringIterator(session, pos, true))
                session.$findClosingBracket('[', pos, newFilteringIterator(session, pos, true))
                session.$findClosingBracket('(', pos, newFilteringIterator(session, pos, true))
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
            left: leftNearest
            right: rightNearest
            mismatch: true
            equals: (object) ->

                if object.left != @left
                    return false
                if object.right != @right
                    return false
                if object.mismatch != @mismatch
                    return false
                return true
            isDefined: -> @left? or @right?

        if result.left && result.right
            expectedRightBracket = session.$brackets[session.getLine(result.left.row).charAt(result.left.column)]
            rightBracket = session.getLine(result.right.row).charAt(result.right.column)
            if  expectedRightBracket == rightBracket
                result.mismatch = false
        return result

    toggleSurroundingBracketsPopup = (editor) ->
        return


    init = (ace, editor, bindKey, candidateToggleSurroundingBracketsPopup) ->
        Range = ace.require("ace/range").Range
        TokenIterator = ace.require("ace/token_iterator").TokenIterator
        if candidateToggleSurroundingBracketsPopup
            toggleSurroundingBracketsPopup = candidateToggleSurroundingBracketsPopup
        session = editor.getSession()
        keyboardHandler =
            name: 'highlightBrackets'
            bindKey: bindKey
            exec: (editor)  ->
                session = editor.getSession()
                if session.$highlightRange
                    clearCurrentHighlight(session)
                else
                    highlightBrackets(editor)
            readOnly: true


        editor.commands.addCommand(keyboardHandler);

        session.getSelection().on("changeCursor", ->
            currentRange = session.$highlightRange
            if currentRange?
                candidateRange = findSurroundingBrackets(editor)
                if (!currentRange.equals(candidateRange) and candidateRange?.isDefined())
                    highlightBrackets(editor, candidateRange)
            return
        )

        session.on("changeScrollTop", ->
            toggleSurroundingBracketsPopup(editor)
            return
        )
        session.on("changeScrollLeft", ->
            toggleSurroundingBracketsPopup(editor)
            return
        )
        return

    return {
        highlightBrackets: highlightBrackets
        findSurroundingBrackets: findSurroundingBrackets
        init: init
    }
)
