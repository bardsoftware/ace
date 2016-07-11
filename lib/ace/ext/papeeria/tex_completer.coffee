define (require, exports, module) ->
  exports.getCompletions = (editor, session, pos, prefix, callback) ->
    wordList = [ '\\item' ]
    callback null, wordList.map((word) ->
      {
        caption: word
        value: word
        meta: 'TEX'
      }
    )
  return
