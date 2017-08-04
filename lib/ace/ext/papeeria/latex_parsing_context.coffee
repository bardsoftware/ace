define((require, exports, module) ->
  PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")

  {
    COMMENT_TOKENTYPE
    ESCAPE_TOKENTYPE
    LPAREN_TOKENTYPE
    RPAREN_TOKENTYPE
    LIST_TOKENTYPE
    EQUATION_TOKENTYPE
    ENVIRONMENT_TOKENTYPE

    SPECIFIC_TOKEN_FOR_STATE
  } = PapeeriaLatexHighlightRules

  # Ordering matters here: tokentypes higher up the list take precedence over lower ones,
  # if token is of multiple types
  CONTEXT_TOKENTYPES = [
    COMMENT_TOKENTYPE
    EQUATION_TOKENTYPE
    ENVIRONMENT_TOKENTYPE
    LIST_TOKENTYPE
  ]

  # Specific for token's system of type in ace
  isType = (token, type) ->
    return token.type.indexOf(type) > -1

  ###
   * @param {(number, number) pos}
   *
   * Returns context at cursor position.
  ###
  getContext = (session, row, column) ->
    { row: nextRow, column: nextColumn } = session.doc.indexToPosition(
      session.doc.positionToIndex({ row, column }, row) + 1,
      row
    )
    token = session.getTokenAt(row, column)
    nextToken = session.getTokenAt(nextRow, nextColumn)
    if token?
      for i in [0..CONTEXT_TOKENTYPES.length-1]
        if (
          isType(token, CONTEXT_TOKENTYPES[i]) or
          nextToken? and isType(nextToken, CONTEXT_TOKENTYPES[i])
        )
          return CONTEXT_TOKENTYPES[i]
    else
      if row > 0
        prevState = session.getState(row - 1)
        prevState = if typeof prevState == "string" then prevState else prevState[prevState.length - 1]
        return SPECIFIC_TOKEN_FOR_STATE[prevState] ? "start"
    return "start"

  getContextFromRow = (session, row) ->
    states = session.getState(row)
    if (Array.isArray(states))
      return states[states.length - 1]
    else
      return states

  exports.getContext = getContext
  exports.isType = isType
  return
)
