foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("ace/lib/oop")
  TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules

  exports.START_STATE = START_STATE = "start"

  exports.LIST_ITEMIZE_STATE = LIST_ITEMIZE_STATE = "list.itemize"
  LIST_ITEMIZE_REGEX = "itemize"

  exports.LIST_ENUMERATE_STATE = LIST_ENUMERATE_STATE = "list.enumerate"
  LIST_ENUMERATE_REGEX = "enumerate"

  exports.MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE = MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE = "math.environment.displayed.numbered"
  MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX = "equation"

  exports.MATH_ENVIRONMENT_DISPLAYED_STATE = MATH_ENVIRONMENT_DISPLAYED_STATE = "math.environment.displayed"
  MATH_ENVIRONMENT_DISPLAYED_REGEX = "equation\\*"

  exports.MATH_TEX_DISPLAYED_STATE = MATH_TEX_DISPLAYED_STATE = "math.tex.displayed"
  MATH_TEX_DISPLAYED_OPENING_REGEX = MATH_TEX_DISPLAYED_CLOSING_REGEX = "\\$\\$"

  exports.MATH_TEX_INLINE_STATE = MATH_TEX_INLINE_STATE = "math.tex.inline"
  MATH_TEX_INLINE_OPENING_REGEX = MATH_TEX_INLINE_CLOSING_REGEX = "\\$"

  exports.MATH_LATEX_DISPLAYED_STATE = MATH_LATEX_DISPLAYED_STATE = "math.latex.displayed"
  MATH_LATEX_DISPLAYED_OPENING_REGEX = "\\\\\\["
  MATH_LATEX_DISPLAYED_CLOSING_REGEX = "\\\\\\]"

  exports.MATH_LATEX_INLINE_STATE = MATH_LATEX_INLINE_STATE = "math.latex.inline"
  MATH_LATEX_INLINE_OPENING_REGEX = "\\\\\\("
  MATH_LATEX_INLINE_CLOSING_REGEX = "\\\\\\)"

  exports.LIST_TOKEN_TYPE = LIST_TOKEN_TYPE = "list"
  exports.EQUATION_TOKEN_TYPE = EQUATION_TOKEN_TYPE = "equation"

  exports.LIST_STATE = LIST_STATE = "list"
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE = "list"
  exports.EQUATION_STATE = EQUATION_STATE = "equation"
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE = "equation"
  exports.ENVIRONMENT_STATE = ENVIRONMENT_STATE = "environment"
  exports.ENVIRONMENT_TOKENTYPE = ENVIRONMENT_TOKENTYPE = "environment"
  exports.TABLE_STATE = "table"
  exports.TABLE_TOKENTYPE = "table"
  exports.FIGURE_STATE = "figure"
  exports.FIGURE_TOKENTYPE = "figure"
  PapeeriaLatexHighlightRules = ->
    ###
      * We maintain a stack of nested LaTeX semantic types (e.g. "document", "section", "list")
      * to be able to provide context for autocompletion and other functions.
      * Stack is constructed by the background highlighter;
      * its elements are then propagated to * the editor session and become
      * available through getContext method.
      *
      * The exact semantics of the rules for the use described in the file tokenizer.js
      * @param {pushedState} string
      * @return {function} function, which correctly puts new type(pushedState) on stack
    ###


    pushState = (pushedState) ->
      return (currentState, stack) ->
        stack.push(pushedState)
        return pushedState

    popState = (currentState, stack) ->
      if not stack?
        throw new Error("papeeria_highlight_rules -- stack error: stack doesn't exist")

      if not Array.isArray(stack)
        if stack != "start"
          throw new Error("papeeria_highlight_rules -- stack error: stack must be 'stack' of array")

        return "start"

      if stack.length == 0
        if currentState != "start"
          throw new Error('papeeria_highlight_rules -- stack error: stack should not be empty here')
        else
          return "start"

      # here we know stack is not empty
      errorMessage = "papeeria_highlight_rules -- stack error: expected " + currentState + " found " + stack[stack.length - 1]
      if currentState != stack[stack.length-1]
        throw new Error(errorMessage)

      stack.pop()
      if stack.length == 0
        return "start"

      return stack[stack.length - 1]

    basicRules = (tokenType) ->
      if (tokenType?)
        addToken = "." + tokenType
      else
        addToken = ""
      return [
        { token: "comment" + addToken, regex: "%.*$" }
        { token: "paren.lparen" + addToken, regex: "[[({]" }
        { token: "paren.rparen" + addToken, regex: "[\\])}]" }
        { token: "storage.type" + addToken, regex: "\\\\[a-zA-Z]+" }
        { token: "constant.character.escape" + addToken, regex: "\\\\[^a-zA-Z]?" }
        { defaultToken : "text" + addToken }
      ]

    beginRule = (text, pushedState) ->
      return {
        token: [
          "storage.type"
          "paren.lparen"
          "variable.parameter"
          "paren.rparen"
        ]
        regex: "(\\\\(?:begin))({)(" + text + ")(})"
        next: pushState(pushedState)
      }

    endRule = (text) ->
      return {
        token: [
          "storage.type"
          "paren.lparen"
          "variable.parameter"
          "paren.rparen"
        ]
        regex: "(\\\\(?:end))({)(" + text + ")(})"

        next: popState
      }

    mathStartRule = (openingRegex, state) -> {
      token: "string.paren.lparen"
      regex: openingRegex
      next: pushState(state)
      merge: false
    }

    mathEndRules = (closingRegex) -> [
      { token: "string.paren.rparen", regex: closingRegex, next: popState }
      { token: "error", regex : "^\\s*$", next: popState }
    ]

    specificTokenForState = {}
    specificTokenForState[LIST_ITEMIZE_STATE] = LIST_TOKEN_TYPE
    specificTokenForState[LIST_ENUMERATE_STATE] = LIST_TOKEN_TYPE
    specificTokenForState[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = EQUATION_TOKEN_TYPE
    specificTokenForState[MATH_ENVIRONMENT_DISPLAYED_STATE] = EQUATION_TOKEN_TYPE
    specificTokenForState[MATH_TEX_INLINE_STATE] = EQUATION_TOKEN_TYPE
    specificTokenForState[MATH_TEX_DISPLAYED_STATE] = EQUATION_TOKEN_TYPE
    specificTokenForState[MATH_LATEX_INLINE_STATE] = EQUATION_TOKEN_TYPE
    specificTokenForState[MATH_LATEX_DISPLAYED_STATE] = EQUATION_TOKEN_TYPE

    equationStartRules = [
      beginRule(MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX, MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE)
      beginRule(MATH_ENVIRONMENT_DISPLAYED_REGEX, MATH_ENVIRONMENT_DISPLAYED_STATE)
      mathStartRule(MATH_TEX_DISPLAYED_OPENING_REGEX, MATH_TEX_DISPLAYED_STATE)
      mathStartRule(MATH_TEX_INLINE_OPENING_REGEX, MATH_TEX_INLINE_STATE)
      mathStartRule(MATH_LATEX_DISPLAYED_OPENING_REGEX, MATH_LATEX_DISPLAYED_STATE)
      mathStartRule(MATH_LATEX_INLINE_OPENING_REGEX, MATH_LATEX_INLINE_STATE)
    ]

    ## This class generates rules for a simple command \commandName{commandBody}
    ## Generated rules:
    ##  -- append given stateName to the list of token types of \commandName and left {
    ##  -- append given instateTokenType to the tokens in the command body
    ## Rules are appended to the arrays which need to be passed afterwards  to other rules
    ## or to the state map @$rules
    class SimpleCommandState
      constructor: (@commandName, @stateName, @instateTokenType) -> {}
      generateRules: (openingRules, instateRules) =>
        opening =
          token: [
            "storage.type"
            "paren.lparen.#{@stateName}"
          ]
          next: pushState(@stateName)
          regex: "(\\\\(?:#{@commandName}))({)"
        openingRules.push(opening)

        closing =
          token: "paren.rparen"
          regex: "(})"
          next: popState
        instateRules.push(closing)
        basicRules(@instateTokenType).forEach((rule) -> instateRules.push(rule))

    listStartRules = [
      beginRule(LIST_ITEMIZE_REGEX, LIST_ITEMIZE_STATE)
      beginRule(LIST_ENUMERATE_REGEX, LIST_ENUMERATE_STATE)
    ]

    genericEnvironmentRule = {
      token: [
        "storage.type"
        "paren.lparen.environment"
        "variable.parameter.environment"
        "paren.rparen"
      ]
      regex: "(\\\\(?:begin|end))({)(\\w*)(})"
    }


    citationsRules = []
    @$rules = {}

    citeCommandState = new SimpleCommandState("cite", "cite", "variable.parameter.cite")
    citationsInstateRules = []
    citeCommandState.generateRules(citationsRules, citationsInstateRules)

    citationsRules = citationsRules.concat([
      {
        token: [
          "storage.type"
          "paren.lparen.ref"
          "variable.parameter.ref"
          "paren.rparen"
        ]
        regex: "(\\\\(?:ref))({)(\\w*)(})"
      }
      # this rule is for `vref` and `vcite` citations
      {
        token: [
          "keyword"
          "paren.lparen"
          "variable.parameter"
          "paren.rparen"
        ]
        regex: "(\\\\(?:v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
      }
    ])
    @$rules[START_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      {
        token: [
          "keyword"
          "paren.lparen"
          "variable.parameter"
          "paren.rparen"
          "paren.lparen"
          "storage.type"
          "paren.rparen"
        ]
        regex: "(\\\\(?:documentclass|usepackage|input))(?:(\\[)([^\\]]*)(\\]))?({)([^}]*)(})"
      }
      genericEnvironmentRule
    ])

    @$rules[LIST_ITEMIZE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      endRule(LIST_ITEMIZE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[LIST_ENUMERATE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      endRule(LIST_ENUMERATE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = [
      endRule(MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX)
    ]

    @$rules[MATH_ENVIRONMENT_DISPLAYED_STATE] = [
      endRule(MATH_ENVIRONMENT_DISPLAYED_REGEX)
    ]

    @$rules[MATH_TEX_INLINE_STATE] = mathEndRules(MATH_TEX_INLINE_CLOSING_REGEX)

    @$rules[MATH_TEX_DISPLAYED_STATE] = mathEndRules(MATH_TEX_DISPLAYED_CLOSING_REGEX)

    @$rules[MATH_LATEX_INLINE_STATE] = mathEndRules(MATH_LATEX_INLINE_CLOSING_REGEX)

    @$rules[MATH_LATEX_DISPLAYED_STATE] = mathEndRules(MATH_LATEX_DISPLAYED_CLOSING_REGEX)

    # if there is no specific token for `state` (like for "start"), then
    # `specificTokenForState[state]` is just undefined, and this is handled
    # inside `basicRules` function
    for state of @$rules
      @$rules[state] = @$rules[state].concat(basicRules(specificTokenForState[state]))
    @$rules[citeCommandState.stateName] = citationsInstateRules
    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
)
