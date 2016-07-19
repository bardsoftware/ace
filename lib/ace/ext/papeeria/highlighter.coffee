define((require, exports, module) ->

    Range = require("ace/range").Range;

    highlightBrackets = (editor) ->
        pos = findSurroundingBrackets(editor)
        session = editor.getSession()
        if session.$bracketHighlightRight || session.$bracketHighlightLeft
            session.removeMarker(session.$bracketHighlightLeft)
            session.removeMarker(session.$bracketHighlightRight)
            session.$bracketHighlightLeft = null
            session.$bracketHighlightRight = null
            return
        if !pos.mismatch
            rangeLeft = new Range(pos.left.row, pos.left.column, pos.left.row, pos.left.column + 1)
            rangeRight = new Range(pos.right.row, pos.right.column, pos.right.row, pos.right.column + 1)
            session.$bracketHighlightLeft = session.addMarker(rangeLeft, "ace_bracket", "text")
            session.$bracketHighlightRight = session.addMarker(rangeRight, "ace_bracket", "text")
        else
            if pos.left && pos.right
                range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
                session.$bracketHighlightLeft = session.addMarker(range, "ace_error-marker", "text")
            if pos.left && !pos.right
                rangeLeft = new Range(pos.left.row, pos.left.column, Infinity, Infinity)
                session.$bracketHighlightLeft = session.addMarker(rangeLeft, "ace_error-marker", "text")
            if pos.right && !pos.left
                rangeRight = new Range(0, 0, pos.right.row, pos.right.column + 1)
                session.$bracketHighlightRight = session.addMarker(rangeRight, "ace_error-marker", "text")
        return

    findSurroundingBrackets = (editor) ->
        positionRightwards = editor.getCursorPosition()
        # if Tokeniterator is created from the cursor position, its first token
        # will be the one which immediately precedes the position (its start+length>=position)
        # The first token is skipped when stepping backwards, so if cursor is positioned immediately
        # after closing bracket } then this bracket will be ignored and ultimately findOpeningBracket
        # will return wrong result (e.g. for this text: {\foo}_  it will return { as the result)
        # To fix it we increment columnin the position for searching leftwards.
        positionLeftwards = editor.getCursorPosition()
        positionLeftwards.column += 1
        session = editor.getSession()
        allBrackets =
            left: [
                session.$findOpeningBracket('}', positionLeftwards, /(\.?.paren)+/)
                session.$findOpeningBracket(']', positionLeftwards, /(\.?.paren)+/)
                session.$findOpeningBracket(')', positionLeftwards, /(\.?.paren)+/)
            ]
            right: [
                session.$findClosingBracket('{', positionRightwards, /(\.?.paren)+/)
                session.$findClosingBracket('[', positionRightwards, /(\.?.paren)+/)
                session.$findClosingBracket('(', positionRightwards, /(\.?.paren)+/)
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
                for key of @
                    if object[key] != @[key]
                        return false;
                return true;
        ###closingBrackets =
            ")": "("
            "]": "["
            "}": "{"
        openingBrackets =
            "(": ")"
            "[": "]"
            "{": "}"

        # Next two 'if' needs to avoid conflict with the standard highlight
        if result.mismatch && session.getLine(position.row).charAt(position.column - 1) of closingBrackets
            result.right =
                row: position.row
                column: position.column - 1
        if result.mismatch && session.getLine(position.row).charAt(position.column - 1) of openingBrackets
            result.left =
                row: position.row
                column: position.column - 1###
        if result.left && result.right
            expectedRightBracket = session.$brackets[session.getLine(result.left.row).charAt(result.left.column)]
            rightBracket = session.getLine(result.right.row).charAt(result.right.column)
            if  expectedRightBracket == rightBracket
                result.mismatch = false
        session.$positionOfHighlight = result
        return result

    exports.highlighter =
        highlightBrackets: highlightBrackets
        findSurroundingBrackets: findSurroundingBrackets
)
