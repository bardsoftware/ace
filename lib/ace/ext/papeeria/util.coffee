define((require, exports, module) ->
  exports.isType = isType = (token, type) ->
    return token.type.indexOf(type) > -1
  return
)
