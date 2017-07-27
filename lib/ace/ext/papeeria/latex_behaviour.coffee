define((require, exports, module) ->
  Behaviour = require("ace/mode/behaviour").Behaviour
  COMMENT_TYPE = "comment"
  ESCAPE_TYPE = "escape"
  MATH_TYPE = "math"
  EQUATION_TYPE = "equation"
  RPAREN_TYPE = "rparen"
  CORRESPONDING_CLOSING = {
      '(': ')'
      '[': ']'
      '{': '}'
  }


  # If we're on the start of a line, but the current token is of a type "comment", we're not actually
  # inside a comment, just on a start of it. That's the reason for `column != 0` check
  isCommentToken = (token, column) -> column != 0 and token? and token.type.indexOf(COMMENT_TYPE) > -1


  isEscapedInsertion = (token, column) -> (
      token? and
      token.type.indexOf(ESCAPE_TYPE) > -1 and
      column - token.start == 1
  )


  isInEquation = (session, row, column) ->
    token = session.getTokenAt(row, column)
    nextToken = session.getTokenAt(row, column + 1)
    state = session.getState(row)
    pState = session.getState(row - 1)
    lastState = if typeof(state) == "string" then state else state[state.length - 1]
    lastPrevState = if typeof(pState) == "string" then pState else pState[pState.length - 1]
    return (
        # This handles the case, when the cursor is on the empty string
        (not token? and lastPrevState.indexOf(MATH_TYPE) > -1) or
        # This handles the common case, when the cursor is inside the equation
        (token? and token.type.indexOf(EQUATION_TYPE) > -1) or
        # This handles the specific case, when the cursor is on the very start of the equation
        (nextToken? and nextToken.type.indexOf(EQUATION_TYPE) > -1)
    )


  DO_NOTHING = null
  AUTO_INSERT = { text: "$$", selection: [1, 1] }
  SKIP = { text: "", selection: [1, 1] }
  dollarsInsertionAction = (state, action, editor, session, text) ->
    if text == '$' and not editor.inMultiSelectMode

      { row, column } = editor.getCursorPosition()
      line = session.getLine(row)

      selection = editor.getSelectionRange()
      selected = session.getTextRange(selection)
      # If some text is selected, we surround it with $
      if selected != ""
        if editor.getWrapBehavioursEnabled()
          return getWrapped(selection, selected, text, text)
        else
          return DO_NOTHING

      token = session.getTokenAt(row, column)
      nextToken = session.getTokenAt(row, column + 1)

      # If cursor is inside a comment or escaped, do nothing
      if isCommentToken(token, column) or isEscapedInsertion(token, column)
        return DO_NOTHING

      prevChar = line[column - 1] or ''
      nextChar = line[column] or ''

      # If cursor is in equation, either skip closing $ or do nothing
      if isInEquation(session, row, column)
        return if nextChar == '$' then SKIP else DO_NOTHING

      # Otherwise, insert or skip
      shouldSkip = (nextChar == '$' and (prevChar != '$' or nextToken.type.indexOf(RPAREN_TYPE) > -1))
      return if shouldSkip then SKIP else AUTO_INSERT


  dollarsDeletionAction = (state, action, editor, session, range) ->
    if editor.inMultiSelectMode
      return DO_NOTHING

    selected = session.doc.getTextRange(range)
    if range.isMultiLine() or selected != '$'
      return DO_NOTHING

    line = session.getLine(range.start.row)
    token = session.getTokenAt(range.end.row, range.end.column)
    nextChar = line[range.start.column + 1]
    # If we're surrounded by $s, delete them
    if nextChar == '$' and not (token.type.indexOf(ESCAPE_TYPE) > -1)
      range.end.column++
      return range


  getWrapped = (selection, selected, opening, closing) ->
    rowDiff = selection.end.row - selection.start.row
    return {
        text: opening + selected + closing,
        selection: [
            0,
            selection.start.column + 1,
            rowDiff,
            selection.end.column + (if rowDiff != 0 then 0 else 1)
        ]
    }


  SKIP_TWO = { text: "", selection: [2, 2] }
  getBracketInsertionAction = (opening) ->
    closing = CORRESPONDING_CLOSING[opening]
    return (state, action, editor, session, text) ->
      if editor.inMultiSelectMode
        return DO_NOTHING

      { row, column } = editor.getCursorPosition()
      line = session.getLine(row)

      switch text
        when opening
          # Handle non-empty selection case
          selection = editor.getSelectionRange()
          selected = session.getTextRange(selection)
          # If some text is selected, we surround it with brackets
          if selected != ""
            if editor.getWrapBehavioursEnabled()
              return getWrapped(selection, selected, opening, closing)
            else
              return DO_NOTHING

          token = session.getTokenAt(row, column)
          # Handle escaped bracket case
          if isEscapedInsertion(token, column)
            shouldComplete = (
                opening != '{' and
                not isInEquation(session, row, column)
            )
            if shouldComplete
              return {
                  text: opening + '\\' + closing,
                  selection: [1, 1]
              }
            else
              return DO_NOTHING

          # Handle default case
          if not editor.completer?.activated and not isCommentToken(token, column)
            return { text: opening + closing, selection: [1, 1] }

        when closing
          nextChar = line[column]
          # Handle skipping when inserting closing bracket
          if nextChar == closing
            matching = session.$findOpeningBracket(closing, { column: column + 1, row: row })
            if matching?
              return SKIP
            else
              return DO_NOTHING

          if opening == '{'
            return DO_NOTHING

          nextToken = session.getTokenAt(row, column + 1)
          # Handle skipping math closing boundary when inserting appropriate bracket
          if nextChar == "\\" and
              line[column + 1] == closing and
              nextToken.type.indexOf(RPAREN_TYPE) > -1
            return SKIP_TWO


  getBracketsDeletionAction = (opening) ->
    closing = CORRESPONDING_CLOSING[opening]
    return (state, action, editor, session, range) ->
      if editor.inMultiSelectMode or range.isMultiLine()
        return DO_NOTHING

      selected = session.doc.getTextRange(range)
      if selected != opening
        return DO_NOTHING

      # Handle common bracket deletion case
      { row, column } = range.start
      line = session.doc.getLine(row)
      nextChar = line[column + 1]
      if nextChar == closing
        range.end.column += 1
        return range

      # Escaped { is just an escaped {, so we do nothing in this case
      if opening == '{'
        return DO_NOTHING

      # Handle math boundaries deletion case
      prevChar = line[column - 1]
      nextNextChar = line[column + 2]
      if prevChar == '\\' and nextChar == '\\' and nextNextChar == closing
        range.end.column += 2
        return range


  class LatexBehaviour extends Behaviour
    constructor: ->
      @add("dollars", "insertion", dollarsInsertionAction)
      @add("dollars", "deletion", dollarsDeletionAction)

      @add("braces", "insertion", getBracketInsertionAction('{'))
      @add("braces", "deletion", getBracketsDeletionAction('{'))

      @add("parens", "insertion", getBracketInsertionAction('('))
      @add("parens", "deletion", getBracketsDeletionAction('('))

      @add("brackets", "insertion", getBracketInsertionAction('['))
      @add("brackets", "deletion", getBracketsDeletionAction('['))


  exports.LatexBehaviour = LatexBehaviour
  return
)
