foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define
define((require, exports, module) ->
  HashHandler = require("ace/keyboard/hash_handler")
  PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")

  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  ENVIRONMENT_STATE = PapeeriaLatexHighlightRules.ENVIRONMENT_STATE
  TABLE_STATE = PapeeriaLatexHighlightRules.TABLE_STATE
  FIGURE_STATE = PapeeriaLatexHighlightRules.FIGURE_STATE

  EQUATION_SNIPPETS = require("ace/ext/papeeria/snippets/equation_snippets")
  LIST_ENVIRONMENTS = [
    "itemize"
    "enumerate"
    "description"
  ]

  EQUATION_ENVIRONMENTS = [
      "equation"
      "equation*"
  ]

  OTHER_ENVIRONMENTS = [
      "table"
      "figure"
  ]

  ENVIRONMENT_LABELS = for env in EQUATION_ENVIRONMENTS.concat(OTHER_ENVIRONMENTS, LIST_ENVIRONMENTS)
    caption: env
    value: env
    meta: "environments"
    meta_score: 10


  EQUATION_ENV_SNIPPETS = for env in EQUATION_ENVIRONMENTS
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t$1
                \\end{#{env}}
            """
      meta: "equation"
      meta_score: 10


  LIST_END_ENVIRONMENT = for env in LIST_ENVIRONMENTS
      caption: "\\end{#{env}}"
      value: "\\end{#{env}}"
      score: 0
      meta: "End"
      meta_score: 1

  REFERENCE_SNIPPET =
      caption: "\\ref{..."
      snippet: """
            \\ref{${1}}
        """
      meta: "reference and citation"
      meta_score: 10

  CITATION_SNIPPET =
      caption: "\\cite{..."
      snippet: """
            \\cite{${1}}
        """
      meta: "reference and citation"
      meta_score: 10

  compare = (a, b) -> a.caption.localeCompare(b.caption)
  BASIC_SNIPPETS = [
    {
      caption: "\\begin{env}...\\end{env}"
      snippet: """
              \\begin{$1}
              \t $2
              \\end{$1}
            """
      meta: "Any environment"
      meta_score: 100
    }
    {
      caption: "\\begin{...}"
      snippet: """
                \\begin{$1}
            """
      meta: "Any environment"
      meta_score: 8
    }
    {
      caption: "\\end{...}"
      snippet: """
                \\end{$1}
            """
      meta: "Any environment"
      meta_score: 8
    }

    {
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage{${1:package}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\section{..."
      snippet: """
            \\section{${1:name}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\subsection{..."
      snippet: """
            \\subsection{${1:name}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\subsubsection{..."
      snippet: """
            \\subsubsection{${1:name}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\chapter{..."
      snippet: """
            \\chapter{${1:name}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\begin{table}..."
      snippet: """
            \\begin{table}
            \t\\begin{tabular}{${1:tablespec}}
            \t\t $2
            \t\\end{tabular}
            \\end{table}
        """
      meta: "table"
      meta_score: 9
    }
    {
      caption: "\\begin{figure}..."
      snippet: """
            \\begin{figure}[${1:placement}]\n\
            \t $2
            \\end{figure}
        """
      meta: "figure"
      meta_score: 9
    }
  ]
  BASIC_SNIPPETS = BASIC_SNIPPETS.sort(compare)

  LIST_SNIPPET = for env in LIST_ENVIRONMENTS
      caption: "\\begin{#{env}}..."
      snippet: """
                \\begin{#{env}}
                \t\\item $1
                \\end{#{env}}
            """
      meta: "list"
      meta_score: 10


  LIST_KEYWORDS = ["\\item"]
  LIST_KEYWORDS = LIST_KEYWORDS.map((word) ->
    caption: word,
    value: word
    meta: "list"
    meta_score: 10
  )


  getJsonFromUrl = (url, onSuccess) =>
    $.getJSON(url).done((data) => onSuccess(data))

  processReferenceJson = (json) =>
    return json?.map((elem) => {
      name: elem.caption
      value: elem.caption
      score: 1000
      meta: elem.type
      meta_score: 10
    })

  processCitationJson = (json) =>
    result = []
    for bibfile, bibentries of json
      if bibfile != "" && bibentries != ""
        bibentries.map((entry) =>
          result.push(
            name: entry.id
            value: entry.id
            score: 1000
            meta: bibfile
            meta_score: 10
          )
        )
    return result

  class CompletionsCache
    ###
    * processJson -- function -- handler for defined type of json(citeJson, refJson, etc)
    * return object with fields name, value and (optional) meta, meta_score, score
    ###
    constructor: (getJson, processJson) ->
      @lastFetchedUrl =  ""
      @cache = []
      @getJson = getJson
      @processJson = processJson

    getReferences: (url, callback) =>
      if url != @lastFetchedUrl
        @getJson(url, (data) =>
          if data?
            @cache = @processJson(data)
            callback(null, @cache)
            @lastFetchedUrl = url
        )
      else
        callback(null, @cache)

  ###
  * Show popup if token type at the current pos is one of the given array elements.
  * @ (editor) --> editor
  * @ (list of strings) -- allowedTypes
  ###
  showPopupIfTokenIsOneOfTypes = (editor, allowedTypes) ->
    if editor.completer?
      pos = editor.getCursorPosition()
      session = editor.getSession()
      token = session.getTokenAt(pos.row, pos.column)

      if token?
        for type in allowedTypes
          if LatexParsingContext.isType(token, type)
            editor.completer.showPopup(editor)
            break

  class TexCompleter
      constructor: ->
        @refCache = new CompletionsCache(getJsonFromUrl, processReferenceJson)
        @citeCache = new CompletionsCache(getJsonFromUrl, processCitationJson)
        @enabled = true

      init: (editor) =>
        keyboardHandler = new HashHandler.HashHandler()
        keyboardHandler.addCommand(
          name: "add item in list mode"
          bindKey: {win: "enter", mac: "enter"}
          exec: (editor) => return if @enabled then @completeLinebreak(editor) else false
        )
        editor.keyBinding.addKeyboardHandler(keyboardHandler)

        # we need two event handlers because handlers below work fine when we in
        # existing \ref{|} or \cite{|}
        # But doesn't work correct when we added block (\ref{}. \cite. etc) using autocomplete
        editor.commands.on('afterExec', (event) ->
          allowCommand = ["Return", "backspace"]
          if  event.command.name in allowCommand
            showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"])
          );

        editor.getSession().selection.on('changeCursor', (cursorEvent) ->
          showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"])
        );

      setEnabled: (enabled) => @enabled = enabled
      setReferencesUrl: (url) => @referencesUrl = url
      setCitationsUrl: (url) => @citationsUrl = url

      completeLinebreak: (editor) =>
        cursor = editor.getCursorPosition();
        line = editor.session.getLine(cursor.row);
        tabString = editor.session.getTabString();
        indentString = line.match(/^\s*/)[0];
        indexOfBegin = line.indexOf("begin")

        if LatexParsingContext.getContext(editor.session, cursor.row, cursor.column) == LIST_STATE &&  indexOfBegin < cursor.column
          if indexOfBegin > -1
            editor.insert("\n" + tabString + indentString + "\\item ")
          else
            editor.insert("\n" + indentString + "\\item ")
          return true
        else
          return false
      ###
      # callback -- this function is adding list of completions to our popup. Provide by ACE completions API
      # @param {object} error -- convention in node, the first argument to a callback
      # is usually used to indicate an error
      # @param {array} response -- list of completions for adding to popup
      ###
      getCompletions: (editor, session, pos, prefix, callback) =>
        if not @enabled
          callback(null, [])
          return

        token = session.getTokenAt(pos.row, pos.column)
        context = LatexParsingContext.getContext(session, pos.row, pos.column)

        if LatexParsingContext.isType(token, "ref")
          if @referencesUrl? then @refCache.getReferences(@referencesUrl, callback)
          return

        if LatexParsingContext.isType(token, "cite")
          if @citationsUrl? then @citeCache.getReferences(@citationsUrl, callback)
          return

        if (prefix.length >= 2 and prefix[0] == "\\") or (prefix.length >= 3)
          switch context
            when "start" then callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET,
              EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET))
            when LIST_STATE then callback(null, LIST_KEYWORDS.concat(LIST_SNIPPET,
              EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET, LIST_END_ENVIRONMENT))
            when EQUATION_STATE then callback(null, EQUATION_SNIPPETS)
            when ENVIRONMENT_STATE then callback(null, ENVIRONMENT_LABELS)
            else callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET,
              EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET))
           return

        callback(null, [])
        return

  return TexCompleter
)
