foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  "use strict"
  oop = require("ace/lib/oop")
  TextHighlightRules = require("ace/mode/text_highlight_rules").TextHighlightRules
  LIST_REGEX = "itemize|enumerate"
  EQUATION_REGEX = "equation|equation\\*"

  TABLE_REGEX = "table"
  FIGURE_REGEX = "figure"

  LIST_STATE = "list"
  EQUATION_STATE = "equation"
  ENVIRONMENT_STATE = "environment"
  TABLE_STATE = "table"
  FIGURE_STATE = "figure"


  TABLE_TOKENTYPE = "table"
  FIGURE_TOKENTYPE = "figure"
  LIST_TOKENTYPE = "list"
  EQUATION_TOKENTYPE = "equation"
  ENVIRONMENT_TOKENTYPE = "environment"



  exports.EQUATION_STATE = EQUATION_STATE
  exports.LIST_STATE = LIST_STATE
  exports.ENVIRONMENT_STATE = ENVIRONMENT_STATE
  exports.TABLE_STATE = TABLE_STATE
  exports.FIGURE_STATE = FIGURE_STATE


  exports.EQUATION_TOKENTYPE = EQUATION_TOKENTYPE
  exports.LIST_TOKENTYPE = LIST_TOKENTYPE
  exports.ENVIRONMENT_TOKENTYPE = ENVIRONMENT_TOKENTYPE
  exports.FIGURE_TOKENTYPE = FIGURE_TOKENTYPE
  exports.TABLE_TOKENTYPE = TABLE_TOKENTYPE

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
        throw new Error("papeeria_highlight_rules -- stack error: stack doesn't exist")

      if not Array.isArray(stack)
        if stack != "start"
          throw new Error("papeeria_highlight_rules -- stack error: stack must be  'stack' of array")

        return "start"

      if stack.length == 0
        if currentState != "start"
          throw new Error("papeeria_highlight_rules -- stack error: stack should not be empty here")
        else
          return "start"

      # here we know stack is not empty
      errorMessage = "papeeria_highlight_rules -- stack error: expected " + currentState + " found " + stack[stack.length - 1]
      if currentState != stack[stack.length-1] then throw new Error(errorMessage)

      stack.pop()
      if stack.length == 0
        return "start"

      return stack[stack.length - 1]

    # specialized rules for context
    basicRules = (tokenType) -> [
      if (tokenType?)
        addToken = "." + tokenType
      else
        addToken = ""
      {
        token: "comment"
        regex: "%.*$"
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
          "lparen.environment." + ENVIRONMENT_TOKENTYPE
          "variable.parameter." + ENVIRONMENT_TOKENTYPE
          "rparen"
        ]
        regex: "(\\\\(?:begin|end))({)([\\w\\s]*)(})"
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
          "lparen" + addToken
          "variable.parameter" + addToken
          "rparen"
        ]
        regex: "(\\\\(?:v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?"
      }
      {
        token : "string",
        regex : "\\\\\\[",
        next  : pushState("math_latex")
      }

      {
        token : "string",
        regex : "\\${1,2}",
        next  : pushState("math")
      }

      {
        token: "storage.type" + addToken
        regex: "\\\\[a-zA-Z]+"
      }

      {
        token: "constant.character.escape" + addToken
        regex: "\\\\[^a-zA-Z]?"
      }

      {
          defaultToken : "text" + addToken
      }

    ]


    beginRule = (text = "[\\w\\s]*", pushedState = "start") ->
      return {
        token: [
          "storage.type"
          "lparen." + ENVIRONMENT_TOKENTYPE
          "variable.parameter." + ENVIRONMENT_TOKENTYPE
          "rparen"
        ]
        regex: "(\\\\(?:begin))({)(" + text + ")(})"
        next: pushState(pushedState)
      }

    endRule = (text = "[\\w\\s]*") ->
      return {
        token: [
          "storage.type"
          "lparen." + ENVIRONMENT_TOKENTYPE
          "variable.parameter." + ENVIRONMENT_TOKENTYPE
          "rparen"
        ]
        regex: "(\\\\(?:end))({)(" + text + ")(})"

        next: popState
      }


    # Function for constructing $$ $$ and \[ \] rules
    # regex -- (String) -- regex for definition end of Equation
    latexMathModeConstructor = (closingRegex) ->
        [{
            token : "comment",
            regex : "%.*$"
          }, {
            token : "string",
            regex : closingRegex,
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


    specificTokenForContext = {}
    specificTokenForContext[LIST_STATE] = LIST_TOKENTYPE
    specificTokenForContext[EQUATION_STATE] = EQUATION_TOKENTYPE
    specificTokenForContext[TABLE_STATE] = TABLE_TOKENTYPE
    specificTokenForContext[FIGURE_STATE] = FIGURE_TOKENTYPE

    @$rules = {}
    @$rules["start"] = [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)
        beginRule(FIGURE_REGEX, FIGURE_STATE)
        beginRule(TABLE_REGEX, TABLE_STATE)

      ]

    @$rules[EQUATION_STATE] = [

        endRule(EQUATION_REGEX)
    ]

    @$rules[LIST_STATE] = [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)

        endRule(LIST_REGEX)
    ]

    @$rules[TABLE_STATE] = [
      endRule(TABLE_REGEX)
    ]

    @$rules[FIGURE_STATE] = [
      endRule(FIGURE_REGEX)

      #should be filled
    ]

    @$rules["math"] = latexMathModeConstructor("\\${1,2}")
    @$rules["math_latex"] = latexMathModeConstructor("\\\\\\]")

    for key of @$rules
        if (specificTokenForContext[key]?)
          @$rules[key] = @$rules[key].concat(basicRules(specificTokenForContext[key]))
        else if key == "start"
          @$rules[key] = @$rules[key].concat(basicRules())
    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
)
