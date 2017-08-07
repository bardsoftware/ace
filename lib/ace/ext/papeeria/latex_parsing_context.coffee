define((require, exports, module) ->
  PapeeriaLatexHighlightRules = require(
    "ace/ext/papeeria/papeeria_latex_highlight_rules")

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

  exports.COMMENT_CONTEXT = COMMENT_CONTEXT = COMMENT_TOKENTYPE
  exports.EQUATION_CONTEXT = EQUATION_CONTEXT = EQUATION_TOKENTYPE
  exports.ENVIRONMENT_CONTEXT = ENVIRONMENT_CONTEXT = ENVIRONMENT_TOKENTYPE
  exports.LIST_CONTEXT = LIST_CONTEXT = LIST_TOKENTYPE
  # "start" is a (badly named) default context
  exports.START_CONTEXT = START_CONTEXT = "start"

  # Ordering matters here: tokentypes higher up the list take precedence over
  # lower ones, if token is of multiple types
  CONTEXT_TOKENTYPES = [
    COMMENT_TOKENTYPE
    EQUATION_TOKENTYPE
    ENVIRONMENT_TOKENTYPE
    LIST_TOKENTYPE
  ]

  CONTEXTS_FOR_TOKENTYPES = {}
  CONTEXTS_FOR_TOKENTYPES[COMMENT_TOKENTYPE] = COMMENT_CONTEXT
  CONTEXTS_FOR_TOKENTYPES[EQUATION_TOKENTYPE] = EQUATION_CONTEXT
  CONTEXTS_FOR_TOKENTYPES[ENVIRONMENT_TOKENTYPE] = ENVIRONMENT_CONTEXT
  CONTEXTS_FOR_TOKENTYPES[LIST_TOKENTYPE] = LIST_CONTEXT

  isType = (token, type) ->
    return token.type.indexOf(type) > -1

  getContext = (session, row, column) ->
    # column > 0 means that token exists at { row, column } and also that we
    # should use this token's type to infer context
    if column > 0
      { row: nextRow, column: nextColumn } = session.doc.indexToPosition(
        session.doc.positionToIndex({ row, column }, row) + 1,
        row
      )
      # we use both this token and next token to correctly determine context
      # on the very start of it
      token = session.getTokenAt(row, column)
      nextToken = session.getTokenAt(nextRow, nextColumn)
      for contextTokentype in CONTEXT_TOKENTYPES
        if (
          isType(token, contextTokentype) or
          nextToken? and isType(nextToken, contextTokentype)
        )
          return CONTEXTS_FOR_TOKENTYPES[contextTokentype]
    # if column is 0, it makes more sense to use context from the end of a
    # previous line
    else
      if row > 0
        prevState = session.getState(row - 1)
        prevState = (
          if typeof prevState == "string"
          then prevState
          else prevState[prevState.length - 1]
        )
        tokentype = SPECIFIC_TOKEN_FOR_STATE[prevState]
        return (
          if tokentype?
          then CONTEXTS_FOR_TOKENTYPES[tokentype]
          else START_CONTEXT
        )
    return START_CONTEXT

  exports.getContext = getContext
  exports.isType = isType
  return
)
