define( (require, exports, module) ->
  PapeeriaLatexHighlightRules = require('./papeeria_latex_highlight_rules')
  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  equationEnvironments = [
    'equation'
    'equation*'
  ]
  listEnvironments = [
    'itemize'
    'enumerate'
  ]

  basicSnippets = [
    {
      caption: "\\ref{..."
      snippet: """
            \\ref{${1}}
        """
      meta: "base"
    }
    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage{${1  :package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage[${1:[options}]{${2:package}}\n\
        """
      meta: "base"
    }
    {
      caption: "\\newcommand{..."
      snippet: """
            \\newcommand{\\${1:cmd}}[${2:opt}]{${3:realcmd}}${4}\n\
        """
      meta: "base"
    }
  ]
  listSnippets = for env in listEnvironments
    {
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t\\item $1
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
      caption: "\\frac{num}{denom}"
      snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
      meta: "equation"
    }
    {
      caption: "\\sum{n}{i=..}{..}"
      snippet: """
                  \\sum^{${1:n}}_{${2:i=1}}{${3}}
            """
      meta: "equation"
    }
  ]

  equationKeywords = ['\\alpha']
  listKeywords = ['\\item']

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
  istype = (token, type) -> 
    return token.type.lastIndexOf(type) > -1
  
  class ReferenceGetter
    constructor: ->
      @cachedURL =  ""
      @cache = []
    getReference: (url, callback) -> 
      if (url == @cashedURL)
        return @cashe
      else 
        @cachedURL = url
        json = $.getJSON(url)
        thisRef = @
        json.success((data) ->
          callback(data, thisRef)
        )

        return @cache

  exports = class TexCompleter
    constructor: ->
      @r = new ReferenceGetter()
    getCompletions: (editor, session, pos, prefix, callback) ->
      context = session.getContext(pos.row)
      token = session.getTokenAt(pos.row, pos.column)
      console.log(token)
      if istype(token, "ref")
        callback(null, @r.getReference("example.json", (data, r) -> 
          r.cache = data.map((elem) -> 
                          return {
                            name: elem.caption
                            value: elem.caption
                            score: Number.MAX_VALUE
                            meta: "ref"}
                    )
          ))
      else if context == "start"
        callback(null, listSnippets.concat(equationSnippets.concat(basicSnippets)))

      else if context == LIST_STATE
        callback(null, listKeywords_.concat(listSnippets.concat(equationSnippets)))

      else if context == EQUATION_STATE
        callback(null, formulasSnippets.concat(equationKeywords_))
) 