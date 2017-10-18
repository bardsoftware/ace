# Copyright (C) 2017 BarD Software
foo = null

define((require, exports, module) ->
  { TokenIterator } = require("ace/token_iterator")
  { Range } = require("ace/range")


  ###*
   * This class is a wrapper around "ace/token_iterator", limiting token
   * navigation to a given range. It behaves as if it is a regular token
   * iterator within a document, consisting of a text in a given range
   * @class TokenIterator
  ###
  class ConstrainedTokenIterator
    constructor: (@session, @range, row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = false
      else
        { row: tokenRow, column: tokenColumn } = @tokenIterator.getCurrentTokenPosition()
        tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
        @outOfRange = not @range.containsRange(tokenRange)

    getCurrentToken: -> if not @outOfRange then @tokenIterator.getCurrentToken() else null

    getCurrentTokenPosition: -> if not @outOfRange then @tokenIterator.getCurrentTokenPosition() else null

    checkCurTokenInRange: ->
      curToken = @tokenIterator.getCurrentToken()
      if not curToken?
        @outOfRange = true
        return null

      { row: tokenRow, column: tokenColumn } = @tokenIterator.getCurrentTokenPosition()
      tokenRange = new Range(tokenRow, tokenColumn, tokenRow, tokenColumn + curToken.value.length)
      if @range.containsRange(tokenRange)
        @outOfRange = false
        return curToken
      else
        @outOfRange = true
        return null

    stepBackward: ->
      @tokenIterator.stepBackward()
      return @checkCurTokenInRange()

    stepForward: ->
      @tokenIterator.stepForward()
      return @checkCurTokenInRange()

    stepTo: (row, column) ->
      @tokenIterator = new TokenIterator(@session, row, column)
      @outOfRange = not @range.contains(row, column)


  exports = { ConstrainedTokenIterator }
)
