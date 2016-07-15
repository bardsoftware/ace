define((require, exports, module) ->

    Range = require("ace/range").Range;

    highlightingBrackets = (editor) ->
        pos = findSurroundingBrackets(editor)
        session = editor.getSession()
        if session.$bracketHighlightRight || session.$bracketHighlightLeft
            session.removeMarker(session.$bracketHighlightLeft)
            session.removeMarker(session.$bracketHighlightRight)
            session.$bracketHighlightLeft = null
            session.$bracketHighlightRight = null
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

    findSurroundingBrackets = (editor) ->
        position = editor.getCursorPosition()
        session = editor.getSession()
        allBrackets =
            left: [
                session.$findOpeningBracket('}', position, /(\.?.paren)+/)
                session.$findOpeningBracket(']', position, /(\.?.paren)+/)
                session.$findOpeningBracket(')', position, /(\.?.paren)+/)
            ]
            right: [
                session.$findClosingBracket('{', position, /(\.?.paren)+/)
                session.$findClosingBracket('[', position, /(\.?.paren)+/)
                session.$findClosingBracket('(', position, /(\.?.paren)+/)
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
        if result.left and result.right
            if session.$brackets[session.getLine(leftNearest.row).charAt(leftNearest.column)] == session.getLine(rightNearest.row).charAt(rightNearest.column)
                result.mismatch = false
        return result
    module.exports = highlightingBrackets
)