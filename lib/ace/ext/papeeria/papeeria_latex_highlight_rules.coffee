define((require, exports, module) ->
  'use strict'
  oop = require('../../lib/oop')
  TextHighlightRules = require('../../mode/text_highlight_rules').TextHighlightRules

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
    listType = 'itemize|enumerate'
    equationType = 'equation|equation\\*'
    listState = 'list'
    equationState = 'equation'

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
        beginRule(listType, listState)
        beginRule(equationType, equationState)

        endRule(equationType)
        endRule(listType)

      ]
      equationState: [
        beginRule(equationType, equationState)
        beginRule(listType, listState)

        endRule(equationType)
        endRule(listType)

      ]
      listState: [
        beginRule(listType, listState)
        beginRule(equationType, equationState)

        endRule(equationType)
        endRule(listType)
      ]


    for key of @$rules
      for rule of basicRules
        @$rules[key].push(basicRules[rule])

    return

  oop.inherits(PapeeriaLatexHighlightRules, TextHighlightRules)
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return
) 
