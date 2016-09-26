foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("ace/lib/oop")
  TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules

  START_STATE = "start"

  LIST_STATE = "list"
  LIST_REGEX = "itemize|enumerate"
  LIST_TOKENTYPE = "list"

  EQUATION_STATE = "equation"
  EQUATION_REGEX = "equation|equation\\*"
  EQUATION_TOKENTYPE = "equation"

  MATH_STATE = "math"
  MATH_CLOSING_REGEX = "\\${1,2}"

  MATH_LATEX_STATE = "math_latex"
  MATH_LATEX_CLOSING_REGEX = "\\\\\\]"

  exports.EQUATION_STATE = EQUATION_STATE
  exports.LIST_STATE = LIST_STATE
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE
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

    # specialized rules for context
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

    specificTokenForState = {}
    specificTokenForState[LIST_STATE] = LIST_TOKENTYPE
    specificTokenForState[EQUATION_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[MATH_STATE] = EQUATION_TOKENTYPE
    specificTokenForState[MATH_LATEX_STATE] = EQUATION_TOKENTYPE

    @$rules = {}
    @$rules[START_STATE] = [
      beginRule(LIST_REGEX, LIST_STATE)
      beginRule(EQUATION_REGEX, EQUATION_STATE)
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
      { token: "string", regex: "\\\\\\[", next: pushState(MATH_LATEX_STATE) }
      { token: "string", regex: "\\${1,2}", next: pushState(MATH_STATE) }
    ]

    @$rules[EQUATION_STATE] = [
      endRule(EQUATION_REGEX)
    ]

    @$rules[LIST_STATE] = [
      beginRule(EQUATION_REGEX, EQUATION_STATE)
      endRule(LIST_REGEX)
    ]

    @$rules[MATH_STATE] = [
      { token: "string", regex: MATH_CLOSING_REGEX, next: popState }
      { token: "error", regex : "^\\s*$", next: popState }
    ]

    @$rules[MATH_LATEX_STATE] = [
      { token: "string", regex: MATH_LATEX_CLOSING_REGEX, next: popState }
      { token: "error", regex : "^\\s*$", next: popState }
    ]

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
