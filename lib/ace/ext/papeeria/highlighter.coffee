define((require, exports, module) ->

    Range = require("../../range").Range;

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
            range = new Range(pos.left.row, pos.left.column, pos.right.row, pos.right.column + 1)
            session.$bracketHighlightLeft = session.addMarker(range, "ace_selection", "text")
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
        session.$highlightRange = pos
        if pos.left && pos.right
            if (pos.right.row - pos.left.row) > 70
                content = "line " + pos.left.row + ": " + session.getLine(pos.left.row) + "    line " + pos.right.row + ": " + session.getLine(pos.right.row)
                popoverHandler.show($("#line"), content)
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


    popoverHandler = popoverHandler ? {
        options: {
            html: true
            placement: "bottom"
            trigger: "manual"
            container: "#editor"
        }

        show: (jqPopoverContainer, content) ->
            setTimeout(->
                cursorPosition = $("textarea.ace_text-input").position()
                jqPopoverContainer.css({
                  top: cursorPosition.top + 24 + "px"
                  left: cursorPosition.left + "px"
                })
                popoverHandler.options.content = content
                jqPopoverContainer.popover(popoverHandler.options)
                jqPopoverContainer.popover("show")
                return
            , 100)

        hide: (jqPopoverContainer) ->
            jqPopoverContainer.popover("destroy")
    }

    initPopover = (editor) ->
        cssPath = require.toUrl("./highlighter.css")
        linkDemo = $("<link>").attr(
            rel: "stylesheet"
            href: cssPath
        )
        $("head").append(linkDemo)

        span = $("<span>").attr(
            id: "line"
        )

        $("body").append(span)
        return

    init = (editor, bindKey) ->
        initPopover(editor)
        session = editor.getSession()
        keyboardHandler = 
            name: 'highlightBrackets'
            bindKey: bindKey
            exec: (editor)  -> return highlightBrackets(editor)
            readOnly: true


        editor.commands.addCommand(keyboardHandler);

        session.getSelection().on("changeCursor", -> 
            if session.$bracketHighlightLeft || session.$bracketHighlightRight 
                session.removeMarker(session.$bracketHighlightLeft)
                session.removeMarker(session.$bracketHighlightRight)
                session.$bracketHighlightLeft = null
                session.$bracketHighlightRight = null
                if (!isInsideCurrentHighlight())
                    highlightBrackets(editor)
            popoverHandler.hide($("#line"))      
            return
        )

        session.on("changeScrollTop", ->
            popoverHandler.hide($("#line"))
        )

        session.on("changeScrollLeft", ->
            popoverHandler.hide($("#line"))
        )

        isInsideCurrentHighlight = -> 
            oldRange = session.$highlightRange;
            newRange = findSurroundingBrackets(editor)
            return oldRange.equals(newRange);
        return

    exports.highlighter =
        highlightBrackets: highlightBrackets
        findSurroundingBrackets: findSurroundingBrackets
        init: init
)
