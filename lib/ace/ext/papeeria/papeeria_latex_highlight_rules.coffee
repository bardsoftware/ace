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

  exports.COMMENT_TOKENTYPE = COMMENT_TOKENTYPE = "comment"
  exports.ESCAPE_TOKENTYPE = ESCAPE_TOKENTYPE = "escape"
  exports.LPAREN_TOKENTYPE = LPAREN_TOKENTYPE = "lparen"
  exports.RPAREN_TOKENTYPE = RPAREN_TOKENTYPE = "rparen"
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE = "list"
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE = "equation"
  exports.ENVIRONMENT_TOKENTYPE = ENVIRONMENT_TOKENTYPE = "environment"

  exports.SPECIFIC_TOKEN_FOR_STATE = SPECIFIC_TOKEN_FOR_STATE = {}
  SPECIFIC_TOKEN_FOR_STATE[LIST_ITEMIZE_STATE] = LIST_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[LIST_ENUMERATE_STATE] = LIST_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_ENVIRONMENT_DISPLAYED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_TEX_INLINE_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_TEX_DISPLAYED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_LATEX_INLINE_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_LATEX_DISPLAYED_STATE] = EQUATION_TOKENTYPE

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
        { token: "#{COMMENT_TOKENTYPE}#{addToken}", regex: "%.*$" }
        { token: "#{LPAREN_TOKENTYPE}#{addToken}", regex: "[[({]" }
        { token: "#{RPAREN_TOKENTYPE}#{addToken}", regex: "[\\])}]" }
        { token: "storage.type#{addToken}", regex: "\\\\[a-zA-Z]+" }
        { token: "constant.character.#{ESCAPE_TOKENTYPE}#{addToken}", regex: "\\\\[^a-zA-Z]?", merge: false }
        { defaultToken : "text#{addToken}" }
      ]

    beginRule = (text, pushedState) ->
      return {
        token: [
          "storage.type"
          LPAREN_TOKENTYPE
          "variable.parameter"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:begin))({)(#{text})(})"
        next: pushState(pushedState)
      }

    envEndRule = (text) ->
      return {
        token: [
          "storage.type"
          LPAREN_TOKENTYPE
          "variable.parameter"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:end))({)(#{text})(})"

        next: popState
      }

    mathEnvEndRules = (text) -> [
      {
        token: [
          "storage.type"
          LPAREN_TOKENTYPE
          "variable.parameter"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:end))({)(#{text})(})"

        next: popState
      }
      { token: "error.#{EQUATION_TOKENTYPE}", regex : "^\\s*$", next: popState }
    ]

    mathStartRule = (openingRegex, state) -> {
      token: "string.#{LPAREN_TOKENTYPE}"
      regex: openingRegex
      next: pushState(state)
      merge: false
    }

    mathEndRules = (closingRegex) -> [
      { token: "string.#{RPAREN_TOKENTYPE}", regex: closingRegex, next: popState }
      { token: "error.#{EQUATION_TOKENTYPE}", regex : "^\\s*$", next: popState }
    ]

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
            "#{LPAREN_TOKENTYPE}.#{@stateName}"
          ]
          next: pushState(@stateName)
          regex: "(\\\\(?:#{@commandName}))({)"
        openingRules.push(opening)

        closing =
          token: RPAREN_TOKENTYPE
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
        "#{LPAREN_TOKENTYPE}.#{ENVIRONMENT_TOKENTYPE}"
        "variable.parameter.#{ENVIRONMENT_TOKENTYPE}"
        RPAREN_TOKENTYPE
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
          "#{LPAREN_TOKENTYPE}.ref"
          "variable.parameter.ref"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:ref))({)(\\w*)(})"
      }
      # this rule is for `vref` and `vcite` citations
      {
        token: [
          "keyword"
          LPAREN_TOKENTYPE
          "variable.parameter"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
      }
    ])
    @$rules[START_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      {
        token: [
          "keyword"
          LPAREN_TOKENTYPE
          "variable.parameter"
          RPAREN_TOKENTYPE
          LPAREN_TOKENTYPE
          "storage.type"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:documentclass|usepackage|input))(?:(\\[)([^\\]]*)(\\]))?({)([^}]*)(})"
      }
      genericEnvironmentRule
    ])

    @$rules[LIST_ITEMIZE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      envEndRule(LIST_ITEMIZE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[LIST_ENUMERATE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      envEndRule(LIST_ENUMERATE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = mathEnvEndRules(MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX)

    @$rules[MATH_ENVIRONMENT_DISPLAYED_STATE] = mathEnvEndRules(MATH_ENVIRONMENT_DISPLAYED_REGEX)

    @$rules[MATH_TEX_INLINE_STATE] = mathEndRules(MATH_TEX_INLINE_CLOSING_REGEX)

    @$rules[MATH_TEX_DISPLAYED_STATE] = mathEndRules(MATH_TEX_DISPLAYED_CLOSING_REGEX)

    @$rules[MATH_LATEX_INLINE_STATE] = mathEndRules(MATH_LATEX_INLINE_CLOSING_REGEX)

    @$rules[MATH_LATEX_DISPLAYED_STATE] = mathEndRules(MATH_LATEX_DISPLAYED_CLOSING_REGEX)

    # if there is no specific token for `state` (like for "start"), then
    # `SPECIFIC_TOKEN_FOR_STATE[state]` is just undefined, and this is handled
    # inside `basicRules` function
    for state of @$rules
      @$rules[state] = @$rules[state].concat(basicRules(SPECIFIC_TOKEN_FOR_STATE[state]))
    @$rules[citeCommandState.stateName] = citationsInstateRules
    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
)
