define (require, exports, module) ->
  'use strict'
  oop = require('../lib/oop')
  TextHighlightRules = require('./text_highlight_rules').TextHighlightRules

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
          'keyword'
          'lparen'
          'variable.parameter'
          'rparen'
        ]
        regex: '(\\\\(?:label|v?ref|cite(?:[^{]*)))(?:({)([^}]*)(}))?'
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
    @$rules =
      'start': [
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(itemize|enumerate)(})'
          next: pushState('list')
        }
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(equation|equation\\*)(})'
          next: pushState('equation')
        }
      ]
      'equation': [
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(equation|equation\\*)(})'
          next: pushState('equation')
        }
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:end))({)(equation|equation\\*)(})'
          next: popState
        }
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(itemize|enumerate|descriprion)(})'
          next: pushState('list')
        }
      ]
      'list': [
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(itemize|enumerate)(})'
          next: pushState("list")

        }
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:end))({)(itemize|enumerate|description)(})'
          next: popState
        }
        {
          token: [
            'storage.type'
            'lparen'
            'variable.parameter'
            'rparen'
          ]
          regex: '(\\\\(?:begin))({)(equation|equation\\*)(})'
          next: pushState('equation')        
        }
      ]
    for key of @$rules
      for rule of basicRules
        @$rules[key].push(basicRules[rule])
    console.log('asss', pushState)
    return

  oop.inherits PapeeriaLatexHighlightRules, TextHighlightRules
  exports.PapeeriaLatexHighlightRules = PapeeriaLatexHighlightRules
  return