define((require, exports, module) ->
  Behaviour = require("ace/mode/behaviour").Behaviour
  CStyleBehaviour = require("ace/mode/behaviour/cstyle")

  class LatexBehaviour extends Behaviour
    @getWrapped: (selection, selected, opening, closing) ->
      rowDiff = selection.end.row - selection.end.row
      return {
        text: opening + selected + closing,
        selection: [
          0,
          selection.start.column + 1,
          rowDiff,
          selection.end.column + (if rowDiff != 0 then 0 else 1)
        ]
      }

    constructor: ->
      @$behaviours = {}
      # @cStyleBeviours = CStyleBehaviour().getBehaviours()

      @add("dollars", "insertion", @dollarsInsertionBehaviour)
      @add("dollars", "deletion", @dollarsDeletionBehaviour)

      # @add("braces", "insertion", @bracesInsertionBehaviour)
      # @add("braces", "deletion", @bracesDeletionBehaviour)

      # @add("parens", "insertion", @parensInsertionBehaviour)
      # @add("parens", "deletion", @parensDeletionBehaviour)

      # @add("brackets", "insertion", @bracketsInsertionBehaviour)
      # @add("brackets", "deletion", @bracketsDeletionBehaviour)

    dollarsInsertionBehaviour: (state, action, editor, session, text) =>
      if text == '$'
        { row, column } = editor.getCursorPosition()
        line = session.getLine(row)

        token = session.getTokenAt(row, column)
        if not token?
          return {
            text: "$$",
            selection: [1, 1]
          }
        if /comment/.test(token.type)
          return null

        selection = editor.getSelectionRange()
        selected = session.getTextRange(selection)
        if selected != ""
          if editor.getWrapBehavioursEnabled()
            return LatexBehaviour.getWrapped(selection, selected, text, text)
          else
            return null

        prevChar = line.substring(column - 1, column)
        nextChar = line.substring(column, column + 1)

        if /escape/.test(token.type) and token.value != "\\\\"
          return null

        nextToken = session.getTokenAt(row, column + 1)

        lastState = if typeof(state) == "string" then state else state[state.length - 1]
        inEquation = (
          /equation/.test(token.type) or
          (nextToken? and /equation/.test(nextToken.type)) or
          (not nextToken? and /math/.test(lastState))
        )
        if inEquation
          if nextChar == '$'
            return {
              text: "",
              selection: [1, 1]
            }
          else
            return null

        if nextChar == '$' and (prevChar != '$' or /rparen/.test(nextToken.type))
          return {
            text: "",
            selection: [1, 1]
          }

        return {
          text: "$$",
          selection: [1, 1]
        }

    dollarsDeletionBehaviour: (state, action, editor, session, range) =>
      selected = session.doc.getTextRange(range)
      if range.isMultiLine() or selected != '$'
        return null

      line = session.getLine(range.start.row)
      token = session.getTokenAt(range.end.row, range.end.column)
      nextChar = line.substring(range.start.column + 1, range.start.column + 2)
      console.log(token)
      if nextChar == '$' and not /escape/.test(token.type)
        range.end.column++
        return range

  exports.LatexBehaviour = LatexBehaviour
  return
)
