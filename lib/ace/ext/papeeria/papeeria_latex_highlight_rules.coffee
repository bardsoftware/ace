foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("../../lib/oop")
  TextHighlightRules = require("../../mode/text_highlight_rules").TextHighlightRules
  LIST_REGEX = "itemize|enumerate"
  EQUATION_REGEX = "equation|equation\\*"
  LIST_STATE = "list"
  EQUATION_STATE = "equation"
  LIST_TOKENTYPE = 'list'
  EQUATION_TOKENTYPE = 'equation'

  exports.EQUATION_STATE = EQUATION_STATE
  exports.LIST_STATE = LIST_STATE
  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE
  PapeeriaLatexHighlightRules = ->
    ###*
    * We maintain a stack of nested LaTeX semantic types (e.g. "document", "section", "list"
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
        return 'start'

      if currentState != stack[stack.length - 1]
        throw new Error("papeeria highlight rules stack error")
      stack.pop()
      if stack.length == 0
        return 'start'

      top = stack.pop()
      stack.push(top)

      return top

    basicRules = [
      {
        token: "comment"
        regex: "%.*$"
      }
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
          "keyword"
          "lparen"
          "variable.parameter"
          "rparen"
        ]
        regex: "(\\\\(?:label|v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
      }
      {
        token : "string",
        regex : "\\\\\\[",
        next  : pushState("math_latex")
      }
      {
        token: "storage.type"
        regex: "\\\\[a-zA-Z]+"
      }
      {
        token: "lparen"
        regex: "[[({]"
      }
      {
        token: "rparen"
        regex: "[\\])}]"
      }
      {
        token: "constant.character.escape"
        regex: "\\\\[^a-zA-Z]?"
      }
      {
        token : "string",
        regex : "\\${1,2}",
        next  : pushState("math")
      }

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


    # Function for constructing $$ $$ and \[ \] rules
    # regex -- (String) -- regex for definition end of Equation
    latexMathModeConstructor = (regexOfEnd) ->
        [{
            token : "comment",
            regex : "%.*$"
          }, {
            token : "string",
            regex : regexOfEnd,
            next  : popState
          }, {
            token: "storage.type." + EQUATION_TOKENTYPE
            regex: "\\\\[a-zA-Z]+"
          }, {
            token: "constant.character.escape." + EQUATION_TOKENTYPE
            regex: "\\\\[^a-zA-Z]?"
          }, {
            token : "error." + EQUATION_TOKENTYPE,
            regex : "^\\s*$",
            next : popState
          }, {
            defaultToken : "string." + EQUATION_TOKENTYPE
          }
        ]

    # For unknown reasons  we can"t use constants in block below, because background_tokenizer
    # doesn"t like constants. It wants string literal
    @$rules =
      "start": [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)

      ]
      "equation": [
        beginRule(EQUATION_REGEX, EQUATION_STATE)
        beginRule(LIST_REGEX, LIST_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)

        # will be simplified
        # adds the necessary type of the token
        # for provide context for one line
        {
          token: "storage.type." + EQUATION_TOKENTYPE
          regex: "\\\\[a-zA-Z]+"
        }

        {
          token: "constant.character.escape." + EQUATION_TOKENTYPE
          regex: "\\\\[^a-zA-Z]?"
        }

        {
          defaultToken : "text." + EQUATION_TOKENTYPE
        }
      ]
      "list": [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)

        # will be simplified
        # adds the necessary type of the token
        # for provide context for one line
        {
          token : "string",
          regex : "\\\\\\[",
          next  : pushState("math_latex")
        }
        {
          token: "storage.type." + LIST_TOKENTYPE
          regex: "\\\\[a-zA-Z]+"
        }
        {
          token: "constant.character.escape." + LIST_TOKENTYPE
          regex: "\\\\[^a-zA-Z]?"
        }

        {
          defaultToken : "text." + LIST_TOKENTYPE
        }
      ]

      "math" : latexMathModeConstructor("\\${1,2}")
      "math_latex" : latexMathModeConstructor("\\\\\\]")

    for key of @$rules
      for rule of basicRules
        @$rules[key].push(basicRules[rule])

    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
)
