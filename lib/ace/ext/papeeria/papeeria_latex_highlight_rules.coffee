foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("ace/lib/oop")
  TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules

  START_STATE = "start"

  LIST_ITEMIZE_STATE = "list.itemize"
  LIST_ITEMIZE_REGEX = "itemize"

  LIST_ENUMERATE_STATE = "list.enumerate"
  LIST_ENUMERATE_REGEX = "enumerate"

  EQUATION_REGULAR_STATE = "equation.regular"
  EQUATION_REGULAR_REGEX = "equation"

  EQUATION_ASTERISK_STATE = "equation.asterisk"
  EQUATION_ASTERISK_REGEX = "equation\\*"

  MATH_MULTILINE_STATE = "math.multiline"
  MATH_MULTILINE_OPENING_REGEX = MATH_MULTILINE_CLOSING_REGEX = "\\$\\$"

  MATH_INLINE_STATE = "math.inline"
  MATH_INLINE_OPENING_REGEX = MATH_INLINE_CLOSING_REGEX = "\\$"

  MATH_ALTERNATIVE_STATE = "math.alternative"
  MATH_ALTERNATIVE_OPENING_REGEX = "\\\\\\["
  MATH_ALTERNATIVE_CLOSING_REGEX = "\\\\\\]"

  LIST_STATE = "list"
  LIST_TOKENTYPE = "list"
  EQUATION_STATE = "equation"
  EQUATION_TOKENTYPE = "equation"

  exports.LIST_STATE = LIST_STATE
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE
  exports.EQUATION_STATE = EQUATION_STATE
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE
  PapeeriaLatexHighlightRules = ->
    ###*
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
        { token: "lparen" + addToken, regex: "[[({]" }
        { token: "rparen" + addToken, regex: "[\\])}]" }
        { token: "storage.type" + addToken, regex: "\\\\[a-zA-Z]+" }
        { token: "constant.character.escape" + addToken, regex: "\\\\[^a-zA-Z]?" }
        { defaultToken : "text" + addToken }
      ]

    beginRule = (text = "\\w*", pushedState = "start") ->
      return {
        token: [
          "storage.type"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:begin))({)(" + text + ")(})"
        next: pushState(pushedState)
      }

    endRule = (text = "\\w*") ->
      return {
        token: [
          "storage.type"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:end))({)(" + text + ")(})"

        next: popState
      }

    mathStartRule = (openingRegex, state) -> {
      token: "string"
      regex: openingRegex
      next: pushState(state)
      merge: false
    }

    mathEndRules = (closingRegex) -> [
      { token: "string", regex: closingRegex, next: popState }
      { token: "error", regex : "^\\s*$", next: popState }
    ]

    specificTokenForState = {}
    specificTokenForState[LIST_ITEMIZE_STATE] = LIST_TOKENTYPE
    specificTokenForState[LIST_ENUMERATE_STATE] = LIST_TOKENTYPE
    specificTokenForState[EQUATION_REGULAR_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[EQUATION_ASTERISK_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[MATH_INLINE_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[MATH_MULTILINE_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[MATH_ALTERNATIVE_STATE] = EQUATION_TOKENTYPE

    equationStartRules = [
      beginRule(EQUATION_REGULAR_REGEX, EQUATION_REGULAR_STATE)
      beginRule(EQUATION_ASTERISK_REGEX, EQUATION_ASTERISK_STATE)
      mathStartRule(MATH_MULTILINE_OPENING_REGEX, MATH_MULTILINE_STATE)
      mathStartRule(MATH_INLINE_OPENING_REGEX, MATH_INLINE_STATE)
      mathStartRule(MATH_ALTERNATIVE_OPENING_REGEX, MATH_ALTERNATIVE_STATE)
    ]

    citationsRules = [
      {
        token: [
          "storage.type"
          "lparen.ref"
          "variable.parameter.ref"
          "rparen"
        ]
        regex: "(\\\\(?:ref))({)(\\w*)(})"
      }
      {
        token: [
          "storage.type"
          "lparen.cite"
          "variable.parameter.cite"
          "rparen"
        ]
        regex: "(\\\\(?:cite))({)(\\w*)(})"
      }
      {
        token: [
          "keyword"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
      }
    ]

    listStartRules = [
      beginRule(LIST_ITEMIZE_REGEX, LIST_ITEMIZE_STATE)
      beginRule(LIST_ENUMERATE_REGEX, LIST_ENUMERATE_STATE)
    ]

    @$rules = {}
    @$rules[START_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      {
        token: [
          "keyword"
          "lparen"
          "variable.parameter"
          "rparen"
          "lparen"
          "storage.type"
          "rparen"
        ]
        regex: "(\\\\(?:documentclass|usepackage|input))(?:(\\[)([^\\]]*)(\\]))?({)([^}]*)(})"
      }
      {
        token: [
          "storage.type"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:begin|end))({)(\\w*)(})"
      }
    ])

    @$rules[LIST_ITEMIZE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      endRule(LIST_ITEMIZE_REGEX)
      {
        token: [
          "storage.type"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:begin|end))({)(\\w*)(})"
      }
    ])

    @$rules[LIST_ENUMERATE_STATE] = [].concat(equationStartRules, listStartRules, citationsRules, [
      endRule(LIST_ENUMERATE_REGEX)
      {
        token: [
          "storage.type"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:begin|end))({)(\\w*)(})"
      }
    ])

    @$rules[EQUATION_REGULAR_STATE] = [
      endRule(EQUATION_REGULAR_REGEX)
    ]

    @$rules[EQUATION_ASTERISK_STATE] = [
      endRule(EQUATION_ASTERISK_REGEX)
    ]

    @$rules[MATH_INLINE_STATE] = mathEndRules(MATH_INLINE_CLOSING_REGEX)

    @$rules[MATH_MULTILINE_STATE] = mathEndRules(MATH_MULTILINE_CLOSING_REGEX)

    @$rules[MATH_ALTERNATIVE_STATE] = mathEndRules(MATH_ALTERNATIVE_CLOSING_REGEX)

    # if there is no specific token for `state` (like for "start"), then
    # `specificTokenForState[state]` is just undefined, and this is handled
    # inside `basicRules` function
    for state of @$rules
      @$rules[state] = @$rules[state].concat(basicRules(specificTokenForState[state]))

    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
)
