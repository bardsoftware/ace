foo = null # ACE builder wants some meaningful JS code here to use ace.define instead of just define

define((require, exports, module) ->
  HashHandler = require("ace/keyboard/hash_handler")
  PapeeriaLatexHighlightRules = require("ace/ext/papeeria/papeeria_latex_highlight_rules")
  LatexParsingContext = require("ace/ext/papeeria/latex_parsing_context")


  EQUATION_STATE = PapeeriaLatexHighlightRules.EQUATION_STATE
  LIST_STATE = PapeeriaLatexHighlightRules.LIST_STATE
  EQUATION_SNIPPETS = require("./snippets/equation_snippets")

  LIST_ENVIRONMENTS = [
    "itemize"
    "enumerate"
  ]

  EQUATION_ENVIRONMENTS = [
      "equation"
      "equation*"
  ]


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
      caption: "\\usepackage[]{..."
      snippet: """
            \\usepackage{${1  :package}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\usepackage[options]{..."
      snippet: """
            \\usepackage[${1:[options}]{${2:package}}\n\
        """
      meta: "base"
      meta_score: 9
    }
    {
      caption: "\\newcommand{..."
      snippet: """
            \\newcommand{${1:cmd}}[${2:opt}]{${3:realcmd}}${0}\n\
        """
      meta: "base"
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

  init = (editor, bindKey) ->
    keyboardHandler = new HashHandler.HashHandler()
    keyboardHandler.addCommand(
      name: "add item in list mode"
      bindKey: bindKey
      exec: (editor) ->
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
    )
    editor.keyBinding.addKeyboardHandler(keyboardHandler)

  processReferenceJson = (elem) =>
    return {
      name: elem.caption
      value: elem.caption
      meta: elem.type
      meta_score: 10
    }
  # demo version
  processCitationJson = (elem) =>
    return {
      name: elem.id
      value: elem.id
      meta: elem.type
      meta_score: 10
    }

  class  PropertyGetter
    constructor: (processJson) ->
      @lastFetchedUrl =  ""
      @cache = []
      @processJson = processJson
    processData: (data) =>
      @cache = data?.map(@processJson)

    getReferences: (url, callback) =>
      if url != @lastFetchedUrl
        $.getJSON(url).done((data) =>
          @processData(data)
          callback(null, @cache)
          @lastFetchedUrl = url
        )
      else
        callback(null, @cache)

  ###
  # Show popup if token.type at current pos is one of allowedTypes[i]
  # @ (editor) --> editor
  # @ (list of strings) -- allowedTypes
  ###
  showPopupIfTokenIsOneOfTypes = (editor, allowedTypes) ->
    if editor.completer?
      pos = editor.getCursorPosition()
      session = editor.getSession()
      token = editor.session.getTokenAt(pos.row, pos.column)

      if token?
        for type in allowedTypes
          if LatexParsingContext.isType(token, type)
            editor.completer.showPopup(editor)

  class TexCompleter
      constructor: ->
        @refGetter = new PropertyGetter(processReferenceJson)
        @citeGetter = new PropertyGetter(processCitationJson)
      @init: (editor) ->
        init(editor,  {win: "enter", mac: "enter"})

        # Auto showing popup in ref, cite and other context
        editor.commands.on('afterExec', (event) ->
          allowCommand = ["Return", "backspace"]
          if  event.command.name in allowCommand
            showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"])
        );

        editor.getSession().selection.on('changeCursor', (cursorEvent) ->
          showPopupIfTokenIsOneOfTypes(editor, ["ref", "cite"])
        );
      setReferencesUrl: (url) => @referencesUrl = url
      setCitationsUrl: (url) => @citationsUrl = url

      ###
      # callback -- this function is adding list of completions to our popup. Provide by ACE completions API
      # @param {object} error -- convention in node, the first argument to a callback
      # is usually used to indicate an error
      # @param {array} response -- list of completions for adding to popup
      ###
      getCompletions: (editor, session, pos, prefix, callback) =>
        token = session.getTokenAt(pos.row, pos.column)
        context = LatexParsingContext.getContext(session, pos.row, pos.column)

        if LatexParsingContext.isType(token, "ref")
          if @referencesUrl? then @refGetter.getReferences(@referencesUrl, callback)
        else if LatexParsingContext.isType(token, "cite")
          if @citationsUrl? then @citeGetter.getReferences(@citationsUrl, callback)

        else switch context
          when "start" then callback(null, BASIC_SNIPPETS.concat(LIST_SNIPPET,
            EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET))
          when LIST_STATE then callback(null, LIST_KEYWORDS.concat(LIST_SNIPPET,
            EQUATION_ENV_SNIPPETS, REFERENCE_SNIPPET, CITATION_SNIPPET, LIST_END_ENVIRONMENT))
          when EQUATION_STATE then callback(null, EQUATION_SNIPPETS)

  return TexCompleter
)
