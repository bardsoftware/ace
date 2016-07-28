define((require, exports, module) ->

    Range = require("../../range").Range;

    highlightBrackets = (editor) ->
        pos = findSurroundingBrackets(editor)
        session = editor.getSession()
        if session.$bracketMatchHighlight || session.$bracketMismatchHighlight
            session.removeMarker(session.$bracketMatchHighlight)
            session.removeMarker(session.$bracketMismatchHighlight)
            session.$bracketMatchHighlight = null
            session.$bracketMismatchHighlight = null
            if toggleSurroundingBracketsPopup
                toggleSurroundingBracketsPopup(editor)
            return
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
        if toggleSurroundingBracketsPopup
            toggleSurroundingBracketsPopup(editor, pos.left, pos.right)
        return

    findSurroundingBrackets = (editor) ->
        session = editor.getSession();
        # if Tokeniterator is created from the cursor position, its first token
        # will be the one which immediately precedes the position (its start+length>=position)
        # The first token is skipped when stepping backwards, so if cursor is positioned immediately
        # after closing bracket } then this bracket will be ignored and ultimately findOpeningBracket
        # will return wrong result (e.g. for this text: {\foo}_  it will return { as the result)
        # To fix it we increment columnin the position for searching leftwards.
        positionLeftwards = editor.getCursorPosition()
        if session.getLine(positionLeftwards.row).length == positionLeftwards.column
            positionLeftwards.row += 1
            positionLeftwards.column = 0
        else
            positionLeftwards.column += 1

        positionRightwards = editor.getCursorPosition()        

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

                if object.left != @left
                    return false
                if object.right != @right
                    return false
                if object.mismatch != @mismatch
                    return false
                return true
        
        if result.left && result.right
            expectedRightBracket = session.$brackets[session.getLine(result.left.row).charAt(result.left.column)]
            rightBracket = session.getLine(result.right.row).charAt(result.right.column)
            if  expectedRightBracket == rightBracket
                result.mismatch = false
        return result


    init = (editor, bindKey, toggleSurroundingBracketsPopup) ->
        session = editor.getSession()
        keyboardHandler = 
            name: 'highlightBrackets'
            bindKey: bindKey
            exec: (editor)  -> return highlightBrackets(editor)
            readOnly: true


        editor.commands.addCommand(keyboardHandler);

        session.getSelection().on("changeCursor", -> 
            if session.$bracketMatchHighlight || session.$bracketMismatchHighlight
                session.removeMarker(session.$bracketMatchHighlight)
                session.removeMarker(session.$bracketMismatchHighlight)
                session.$bracketMatchHighlight = null
                session.$bracketMismatchHighlight = null
                if (!isInsideCurrentHighlight())
                    highlightBrackets(editor)
            if toggleSurroundingBracketsPopup
                toggleSurroundingBracketsPopup(editor)     
            return
        )

        if toggleSurroundingBracketsPopup

            session.on("changeScrollTop", ->
                toggleSurroundingBracketsPopup(editor)
            )
            session.on("changeScrollLeft", ->
                toggleSurroundingBracketsPopup(editor)
            )

        isInsideCurrentHighlight = -> 
            oldRange = session.$highlightRange;
            newRange = findSurroundingBrackets(editor)
            return oldRange.equals(newRange)
        return

    exports.highlighter =
        highlightBrackets: highlightBrackets
        findSurroundingBrackets: findSurroundingBrackets
        init: init
)
