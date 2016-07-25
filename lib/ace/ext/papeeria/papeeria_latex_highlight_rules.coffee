define((require, exports, module) ->
  'use strict'
  oop = require('../../lib/oop')
  TextHighlightRules = require('../../mode/text_highlight_rules').TextHighlightRules
  LIST_REGEX = 'itemize|enumerate'
  EQUATION_REGEX = 'equation|equation\\*'
  LIST_STATE = 'list'
  EQUATION_STATE = 'equation'
  exports.EQUATION_STATE = EQUATION_STATE
  exports.LIST_STATE = LIST_STATE
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
        if currentState == 'start'
          stack.push(currentState, pushedState)
        else
          stack.push(pushedState)
        return pushedState

    popState = (currentState, stack) ->
      return stack.pop() or 'start'

    basicRules = [
      {
        token: 'comment'
        regex: '%.*$'
      }
      {
        token: [
          'keyword'
          'lparen'
          'variable.parameter'
          'rparen'
          'lparen'
          'storage.type'
          'rparen'
        ]
        regex: '(\\\\(?:documentclass|usepackage|input))(?:(\\[)([^\\]]*)(\\]))?({)([^}]*)(})'
      }

      {
        token: [
          'storage.type'
          'lparen'
          'variable.parameter'
          'rparen'
        ]
        regex: '(\\\\(?:begin|end))({)(\\w*)(})'
      }
      {
        token: [
          'keyword'
          'lparen'
          'variable.parameter'
          'rparen'
        ]
        regex: '(\\\\(?:label|v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?'
      }
      {
        token: 'storage.type'
        regex: '\\\\[a-zA-Z]+'
      }
      {
        token: 'lparen'
        regex: '[[({]'
      }
      {
        token: 'rparen'
        regex: '[\\])}]'
      }
      {
        token: 'constant.character.escape'
        regex: '\\\\[^a-zA-Z]?'
      }
    ]
    

    beginRule = (text = '\\w*', pushedState = 'start') ->
      return {
        token: [
          'storage.type'
          'lparen'
          'variable.parameter'
          'rparen'
        ]
        regex: '(\\\\(?:begin))({)(' + text + ')(})'
        next: pushState(pushedState)
      }

    endRule = (text = '\\w*') ->
      return {
        token: [
          'storage.type'
          'lparen'
          'variable.parameter'
          'rparen'
        ]
        regex: '(\\\\(?:end))({)(' + text + ')(})'

        next: popState
      }

    @$rules =
      'start': [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)

      ]
      'equation': [
        beginRule(EQUATION_REGEX, EQUATION_STATE)
        beginRule(LIST_REGEX, LIST_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)

      ]
      'list': [
        beginRule(LIST_REGEX, LIST_STATE)
        beginRule(EQUATION_REGEX, EQUATION_STATE)

        endRule(EQUATION_REGEX)
        endRule(LIST_REGEX)
      ]


    for key of @$rules
      for rule of basicRules
        @$rules[key].push(basicRules[rule])

    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
) 
