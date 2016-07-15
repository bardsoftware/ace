define (require, exports, module) ->
  'use strict'
  oop = require('../../lib/oop')
  TextHighlightRules = require('../../mode/text_highlight_rules').TextHighlightRules

  PapeeriaLatexHighlightRules = ->

    pushState = (destination) -> (currentState, stack) ->
      if currentState == 'start'
        stack.push(currentState, destination)
      else
        stack.push(destination)
      destination

    popState = (currentState, stack) ->
      stack.pop() or 'start'

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
    beginRule = (text = '\\w*', destination = 'start') -> 
      {
        token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
        regex: '(\\\\(?:begin))({)(' + text + ')(})'
        next: pushState(destination)
      }

    endRule = (text = '\\w*') -> 
      {
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
        beginRule('itemize|enumerate', 'list')
        beginRule('equation|equation\\*', 'equation')
        
        endRule('equation|equation\\*')
        endRule("itemize|enumerate")

      ]
      'equation': [
        beginRule('equation|equation\\*', 'equation')
        beginRule('itemize|enumerate', 'list')

        endRule('equation|equation\\*')
        endRule("itemize|enumerate")

      ]
      'list': [
        beginRule('itemize|enumerate', 'list')
        beginRule('equation|equation\\*', 'equation')

        endRule('equation|equation\\*')
        endRule("itemize|enumerate")
      ]

       
    for key of @$rules
      for rule of basicRules
         @$rules[key].push(basicRules[rule])
    
    return

  oop.inherits PapeeriaLatexHighlightRules, TextHighlightRules
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return