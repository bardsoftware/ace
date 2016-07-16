define (require, exports, module) ->
    equationKeywords = [ '\\alpha' ]
    listKeywords = [ '\\item' ]

    exports.getCompletions = (editor, session, pos, prefix, callback) ->
        context = session.getContext(pos.row)
        if context == 'list'
            callback(null, wordList.map((word) ->
                caption: word
                value: word
                meta: 'list'
            
            ))
        if context == "equation"
            callback(null, equationKeywords.map((word) ->
                    caption: word
                    value: word
                    meta: 'equation'
            ))
    return
