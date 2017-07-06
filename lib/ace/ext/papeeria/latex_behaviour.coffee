define((require, exports, module) ->
  Behaviour = require("ace/mode/behaviour").Behaviour

  isCommentToken = (token) -> token? and /comment/.test(token.type)

  isEscaped = (line, column) -> line[column - 1] == '\\' and line[column - 2] != '\\'

  isInEquation = (session, row, column) ->
    token = session.getTokenAt(row, column)
    nextToken = session.getTokenAt(row, column + 1)
    state = session.getState(row)
    pState = session.getState(row - 1)
    lastState = if typeof(state) == "string" then state else state[state.length - 1]
    lastPrevState = if typeof(pState) == "string" then pState else pState[pState.length - 1]
    return (
      (not token? and /math/.test(lastPrevState)) or
      (token? and /equation/.test(token.type)) or
      (nextToken? and /equation/.test(nextToken.type)) or
      (not nextToken? and /math/.test(lastState))
    )

  dollarsInsertionAction = (state, action, editor, session, text) ->
    if text == '$' and not editor.inMultiSelectMode
      autoInsert = { text: "$$", selection: [1, 1] }
      skip = { text: "", selection: [1, 1] }
      doNothing = null

      { row, column } = editor.getCursorPosition()
      line = session.getLine(row)

      selection = editor.getSelectionRange()
      selected = session.getTextRange(selection)
      if selected != ""
        if editor.getWrapBehavioursEnabled()
          return getWrapped(selection, selected, text, text)
        else
          return doNothing

      token = session.getTokenAt(row, column)
      nextToken = session.getTokenAt(row, column + 1)

      if isCommentToken(token) and column != 0 or isEscaped(line, column)
        return doNothing

      prevChar = line[column - 1] or ''
      nextChar = line[column] or ''

      if isInEquation(session, row, column)
        return if nextChar == '$' then skip else doNothing

      shouldSkip = (nextChar == '$' and (prevChar != '$' or /rparen/.test(nextToken.type)))
      return if shouldSkip then skip else autoInsert

  dollarsDeletionAction = (state, action, editor, session, range) ->
    selected = session.doc.getTextRange(range)
    if range.isMultiLine() or selected != '$'
      return null

    line = session.getLine(range.start.row)
    token = session.getTokenAt(range.end.row, range.end.column)
    nextChar = line[range.start.column + 1]
    if nextChar == '$' and not /escape/.test(token.type)
      range.end.column++
      return range

  getWrapped = (selection, selected, opening, closing) ->
    rowDiff = selection.end.row - selection.end.row
    return {
      text: opening + selected + closing,
      selection: [
        0,
        selection.start.column + 1,
        rowDiff,
        selection.end.column + (if rowDiff != 0 then 0 else 1)
      ]
    }

  correspondingClosing = {
    '(': ')',
    '[': ']'
    '{': '}'
  }

  getBracketInsertionAction = (opening) ->
    closing = correspondingClosing[opening]
    return (state, action, editor, session, text) ->
      { row, column } = editor.getCursorPosition()
      line = session.getLine(row)

      switch text
        when opening
          # Handle non-empty selection case
          selection = editor.getSelectionRange()
          selected = session.getTextRange(selection)
          if selected != ""
            if editor.getWrapBehavioursEnabled()
              return getWrapped(selection, selected, opening, closing)
            else
              return null

          token = session.getTokenAt(row, column)
          # Handle escaped bracket case
          if isEscaped(line, column)
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
              return null

          # Handle default case
          if not editor.completer?.activated and not (isCommentToken(token) and column != 0)
            return { text: opening + closing, selection: [1, 1] }

        when closing
          nextChar = line[column]
          # Handle skipping when inserting closing bracket
          if nextChar == closing
            matching = session.$findOpeningBracket(closing, { column: column + 1, row: row })
            if matching?
              return {
                text: "",
                selection: [1, 1]
              }
            else
              return null

          if opening == '{'
            return null

          # Handle skipping math closing boundary when inserting appropriate bracket
          if nextChar == "\\" and line[column + 1] == closing and isInEquation(session, row, column)
            return {
              text: "",
              selection: [2, 2]
            }

  getBracketsDeletionAction = (opening) ->
    closing = correspondingClosing[opening]
    return (state, action, editor, session, range) ->
      if range.isMultiLine()
        return null

      selected = session.doc.getTextRange(range)
      if selected != opening
        return null

      # Handle common bracket deletion case
      { row, column } = range.start
      line = session.doc.getLine(row)
      nextChar = line[column + 1]
      if nextChar == closing
        range.end.column += 1
        return range

      if opening == '{'
        return null

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
