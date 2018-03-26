foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("ace/lib/oop")
  { TextHighlightRules } = require("ace/mode/text_highlight_rules")

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

  exports.CITE_STATE = CITE_STATE = "cite"
  exports.CITE_COMMAND = CITE_COMMAND = "cite"

  exports.REF_STATE = REF_STATE = "ref"
  exports.REF_COMMAND = REF_COMMAND = "ref"

  exports.VCITE_STATE = VCITE_STATE = "vcite"
  exports.VCITE_COMMAND = VCITE_COMMAND = "vcite"

  exports.VREF_STATE = VREF_STATE = "vref"
  exports.VREF_COMMAND = VREF_COMMAND = "vref"

  exports.COMMENT_TOKENTYPE = COMMENT_TOKENTYPE = "comment"
  exports.ESCAPE_TOKENTYPE = ESCAPE_TOKENTYPE = "escape"
  exports.LPAREN_TOKENTYPE = LPAREN_TOKENTYPE = "lparen"
  exports.RPAREN_TOKENTYPE = RPAREN_TOKENTYPE = "rparen"
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE = "latexlist"
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE = "equation"
  exports.ENVIRONMENT_TOKENTYPE = ENVIRONMENT_TOKENTYPE = "environment"
  exports.STORAGE_TOKENTYPE = STORAGE_TOKENTYPE = "storage"
  exports.KEYWORD_TOKENTYPE = KEYWORD_TOKENTYPE = "keyword"
  exports.ERROR_TOKENTYPE = ERROR_TOKENTYPE = "error"
  exports.LABEL_TOKENTYPE = LABEL_TOKENTYPE = "label"
  exports.PARAMETER_TOKENTYPE = PARAMETER_TOKENTYPE = "variable.parameter"
  exports.CITE_TOKENTYPE = CITE_TOKENTYPE = "cite.parameter"
  exports.REF_TOKENTYPE = REF_TOKENTYPE = "ref.parameter"
  exports.VCITE_TOKENTYPE = VCITE_TOKENTYPE = "vcite.parameter"
  exports.VREF_TOKENTYPE = VREF_TOKENTYPE = "vref.parameter"

  exports.SPECIFIC_TOKEN_FOR_STATE = SPECIFIC_TOKEN_FOR_STATE = {}
  SPECIFIC_TOKEN_FOR_STATE[LIST_ITEMIZE_STATE] = LIST_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[LIST_ENUMERATE_STATE] = LIST_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_ENVIRONMENT_DISPLAYED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_TEX_INLINE_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_TEX_DISPLAYED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_LATEX_INLINE_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[MATH_LATEX_DISPLAYED_STATE] = EQUATION_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[CITE_STATE] = CITE_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[REF_STATE] = REF_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[VCITE_STATE] = VCITE_TOKENTYPE
  SPECIFIC_TOKEN_FOR_STATE[VREF_STATE] = VREF_TOKENTYPE

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
        { token: "#{STORAGE_TOKENTYPE}.type#{addToken}", regex: "\\\\[a-zA-Z]+" }
        { token: "constant.character.#{ESCAPE_TOKENTYPE}#{addToken}", regex: "\\\\[^a-zA-Z]?", merge: false }
        { defaultToken : "text#{addToken}" }
      ]

    beginRule = (text, pushedState) ->
      return {
        token: [
          "#{STORAGE_TOKENTYPE}.type"
          LPAREN_TOKENTYPE
          PARAMETER_TOKENTYPE
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\begin\\s*)({)(#{text})(})"
        next: pushState(pushedState)
      }

    envEndRule = (text) ->
      return {
        token: [
          "#{STORAGE_TOKENTYPE}.type"
          LPAREN_TOKENTYPE
          PARAMETER_TOKENTYPE
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:end))({)(#{text})(})"

        next: popState
      }

    mathEnvEndRules = (text) -> [
      {
        token: [
          "#{STORAGE_TOKENTYPE}.type"
          LPAREN_TOKENTYPE
          PARAMETER_TOKENTYPE
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\end\\s*)({)(#{text})(})"

        next: popState
      }
    ]

    mathStartRule = (openingRegex, state) -> {
      token: "string.#{LPAREN_TOKENTYPE}"
      regex: openingRegex
      next: pushState(state)
      merge: false
    }

    mathEndRules = (closingRegex) -> [
      { token: "string.#{RPAREN_TOKENTYPE}", regex: closingRegex, next: popState }
    ]

    simpleCommandOpeningRules = (commandName, stateName, stateTokentype) -> [
      {
        token: [
          "#{STORAGE_TOKENTYPE}.type"
          "#{LPAREN_TOKENTYPE}.#{stateTokentype}"
        ]
        next: pushState(stateName)
        regex: "(\\\\(?:#{commandName})\\s*)({)"
      }
    ]

    simpleCommandInStateRules = [
      {
        token: RPAREN_TOKENTYPE
        regex: "(})"
        next: popState
      }
    ]

    mathEmptyLineRule = {
      token: "#{ERROR_TOKENTYPE}.#{EQUATION_TOKENTYPE}", regex : "^\\s*$"
    }

    mathLabelRule = {
      token: [
        "#{STORAGE_TOKENTYPE}.#{LABEL_TOKENTYPE}.#{EQUATION_TOKENTYPE}"
        "#{LPAREN_TOKENTYPE}.#{LABEL_TOKENTYPE}.#{EQUATION_TOKENTYPE}"
        "#{PARAMETER_TOKENTYPE}.#{LABEL_TOKENTYPE}.#{EQUATION_TOKENTYPE}"
        "#{RPAREN_TOKENTYPE}.#{LABEL_TOKENTYPE}.#{EQUATION_TOKENTYPE}"
      ]
      regex: "(\\\\label\\s*)({)([^}]*)(})"
    }

    equationStartRules = [
      beginRule(MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX, MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE)
      beginRule(MATH_ENVIRONMENT_DISPLAYED_REGEX, MATH_ENVIRONMENT_DISPLAYED_STATE)
      mathStartRule(MATH_TEX_DISPLAYED_OPENING_REGEX, MATH_TEX_DISPLAYED_STATE)
      mathStartRule(MATH_TEX_INLINE_OPENING_REGEX, MATH_TEX_INLINE_STATE)
      mathStartRule(MATH_LATEX_DISPLAYED_OPENING_REGEX, MATH_LATEX_DISPLAYED_STATE)
      mathStartRule(MATH_LATEX_INLINE_OPENING_REGEX, MATH_LATEX_INLINE_STATE)
    ]

    listStartRules = [
      beginRule(LIST_ITEMIZE_REGEX, LIST_ITEMIZE_STATE)
      beginRule(LIST_ENUMERATE_REGEX, LIST_ENUMERATE_STATE)
    ]

    genericEnvironmentRule = {
      token: [
        "#{STORAGE_TOKENTYPE}.type"
        "#{LPAREN_TOKENTYPE}.#{ENVIRONMENT_TOKENTYPE}"
        "#{PARAMETER_TOKENTYPE}.#{ENVIRONMENT_TOKENTYPE}"
        RPAREN_TOKENTYPE
      ]
      regex: "(\\\\(?:begin|end)(?:\\s*))({)(\\w*)(})"
    }

    citationsRules = [].concat(
      simpleCommandOpeningRules(CITE_COMMAND, CITE_STATE, CITE_TOKENTYPE),
      simpleCommandOpeningRules(VCITE_COMMAND, VCITE_STATE, VCITE_TOKENTYPE),
      simpleCommandOpeningRules(REF_COMMAND, REF_STATE, REF_TOKENTYPE),
      simpleCommandOpeningRules(VREF_COMMAND, VREF_STATE, VREF_TOKENTYPE)
    )


    @$rules = {}

    @$rules[START_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      {
        token: [
          "#{KEYWORD_TOKENTYPE}"
          LPAREN_TOKENTYPE
          PARAMETER_TOKENTYPE
          RPAREN_TOKENTYPE
          LPAREN_TOKENTYPE
          "#{STORAGE_TOKENTYPE}.type"
          RPAREN_TOKENTYPE
        ]
        regex: "(\\\\(?:documentclass|usepackage|input)(?:\\s*))(?:(\\[)([^\\]]*)(\\]\\s*))?({)([^}]*)(})"
      }
      genericEnvironmentRule
    ])

    @$rules[CITE_STATE] = simpleCommandInStateRules

    @$rules[REF_STATE] = simpleCommandInStateRules

    @$rules[VCITE_STATE] = simpleCommandInStateRules

    @$rules[VREF_STATE] = simpleCommandInStateRules

    @$rules[LIST_ITEMIZE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      envEndRule(LIST_ITEMIZE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[LIST_ENUMERATE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      envEndRule(LIST_ENUMERATE_REGEX)
      genericEnvironmentRule
    ])

    @$rules[MATH_ENVIRONMENT_DISPLAYED_NUMBERED_STATE] = [
      mathEmptyLineRule
      mathLabelRule
    ].concat(mathEnvEndRules(MATH_ENVIRONMENT_DISPLAYED_NUMBERED_REGEX))

    @$rules[MATH_ENVIRONMENT_DISPLAYED_STATE] = [
      mathEmptyLineRule
      mathLabelRule
    ].concat(mathEnvEndRules(MATH_ENVIRONMENT_DISPLAYED_REGEX))

    @$rules[MATH_TEX_INLINE_STATE] = [
      mathEmptyLineRule
    ].concat(mathEndRules(MATH_TEX_INLINE_CLOSING_REGEX))

    @$rules[MATH_TEX_DISPLAYED_STATE] = [
      mathEmptyLineRule
    ].concat(mathEndRules(MATH_TEX_DISPLAYED_CLOSING_REGEX))

    @$rules[MATH_LATEX_INLINE_STATE] = [
      mathEmptyLineRule
    ].concat(mathEndRules(MATH_LATEX_INLINE_CLOSING_REGEX))

    @$rules[MATH_LATEX_DISPLAYED_STATE] = [
      mathEmptyLineRule
    ].concat(mathEndRules(MATH_LATEX_DISPLAYED_CLOSING_REGEX))

    # if there is no specific token for `state` (like for "start"), then
    # `SPECIFIC_TOKEN_FOR_STATE[state]` is just undefined, and this is handled
    # inside `basicRules` function
    for state of @$rules
      @$rules[state] = @$rules[state].concat(basicRules(SPECIFIC_TOKEN_FOR_STATE[state]))
    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules

  exports.isType = (token, type) -> token.type.indexOf(type) > -1

  return
)
