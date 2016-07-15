define((require, exports, module) ->

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
    result
)