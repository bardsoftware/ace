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

  isType = (token, type) ->
    return token.type.indexOf(type) > -1

  getContext = (session, row, column) ->
    # column > 0 means that token exists at { row, column } and also that we should use this token's
    # type to infer context
    if column > 0
      { row: nextRow, column: nextColumn } = session.doc.indexToPosition(
        session.doc.positionToIndex({ row, column }, row) + 1,
        row
      )
      # we use both this token and next token to correctly determine context on the very start of it
      token = session.getTokenAt(row, column)
      nextToken = session.getTokenAt(nextRow, nextColumn)
      for i in [0..CONTEXT_TOKENTYPES.length-1]
        if (
          isType(token, CONTEXT_TOKENTYPES[i]) or
          nextToken? and isType(nextToken, CONTEXT_TOKENTYPES[i])
        )
          return CONTEXT_TOKENTYPES[i]
    # if column is 0, it makes more sense to use context from the end of a previous line
    else
      if row > 0
        prevState = session.getState(row - 1)
        prevState = (
          if typeof prevState == "string"
          then prevState
          else prevState[prevState.length - 1]
        )
        return SPECIFIC_TOKEN_FOR_STATE[prevState] ? "start"
    # "start" is a (badly named) default context
    return "start"

  exports.getContext = getContext
  exports.isType = isType
  return
)
