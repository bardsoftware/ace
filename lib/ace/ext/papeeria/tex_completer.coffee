define (require, exports, module) ->
    equationEnvironments = [
      'equation'
      'equation*'
    ]
    listEnvironments = [
      'itemize'
      'enumerate'
    ]
    
    listSnippets = for env in listEnvironments
        {
            caption: "\\begin{#{env}}..."
            snippet: """
                \\begin{#{env}}
                \t$1
                \\end{#{env}}
            """
            meta: "list"
        }
    equationSnippets = for env in equationEnvironments
      {
        caption: "\\begin{#{env}}..."
        snippet: """
                  \\begin{#{env}}
                  \t$1
                  \\end{#{env}}
              """
        meta: "equation"
      }
    formulasSnippets = [
      {
        caption: "\\frac{..."
        snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
        meta: "equation"
      }
      {
        caption: "\\sum{..."
        snippet: """
                	\\sum^{${1:n}}_{${2:i=1}}{${3}}";
            """
        meta: "equation"
      }
    ]

    equationKeywords = [ '\\alpha' ]
    listKeywords = [ '\\item' ]

    listKeywords_ = listKeywords.map((word) ->
      caption: word,
      value: word
      meta: 'list'

    )
    equationKeywords_ = equationKeywords.map((word) ->
      caption: word,
      value: word
      meta: 'equation'
    )

    exports.getCompletions = (editor, session, pos, prefix, callback) ->
        context = session.getContext(pos.row)
        if context == "start"
            callback(null,  listSnippets.concat equationSnippets)

        if context == 'list'
            callback(null, listKeywords_.concat listSnippets.concat equationSnippets)

        if context == "equation"
            callback(null, formulasSnippets.concat equationKeywords_)
    return