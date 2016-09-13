# Copyright (C) 2016 BarD Software
#
# Utilities for working with texts
#
# @author gkalabin@papeeria.com

define((require, exports, module) ->
  class TextUtils
    ###
    @param {!int} index - zero-based cursor index
    @param {!string} - text where cursor located
    @returns {!CursorPosition} object with cursor's row and column. If index is out of text's bounds it returns the closest position
    @public
    ###
    @idxToPosition: (index, text) ->
      if index <= 0
        return row: 0, column: 0
      lineIdx = 0
      prevLineStartOffset = 0
      newLineRx = /(\n\r?)/gm
      newLineMatch = newLineRx.exec(text)
      while newLineMatch != null
        lineStartOffset = newLineMatch.index + newLineMatch[1].length
        if lineStartOffset > index
          # the index is on the previous line
          return row: lineIdx, column: index - prevLineStartOffset
        lineIdx++
        prevLineStartOffset = lineStartOffset
        newLineMatch = newLineRx.exec(text)
      if index <= text.length
        # the index is on the last line
        return row: lineIdx, column: index - prevLineStartOffset
      else
        # index out of text length bounds - return end position
        return row: lineIdx, column: Math.max(text.length - prevLineStartOffset, 0)

    ###
    @param {!CursorPosition} position - cursor position details
    @param {!string} - text where cursor located
    @returns {!int} index of cursor described by provided position.
      If position is out of text's bounds it returns the closest index
    @public
    ###
    @positionToIdx: (position, text) ->
      if not position? or not position.row? or not position.column?
        return 0
      if position.row < 0 or position.column < 0
        return 0
      lineIdx = 0
      prevLineStartOffset = 0
      newLineRx = /(\n\r?)/gm
      newLineMatch = newLineRx.exec(text)
      while newLineMatch != null
        if lineIdx == position.row
          return Math.min(prevLineStartOffset + position.column, text.length)
        prevLineStartOffset = newLineMatch.index + newLineMatch[1].length
        lineIdx++
        newLineMatch = newLineRx.exec(text)
      return Math.min(text.length, prevLineStartOffset + position.column)

  return TextUtils
)
