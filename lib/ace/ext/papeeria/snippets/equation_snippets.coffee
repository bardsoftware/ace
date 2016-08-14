define((require, exports, module) ->
  equationEnvironments = [
      "equation"
      "equation*"
  ]

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

  SumsAndIntegrals = [
    "\\sum"
    "\\int"
    "\\bigcup"
    "\\bigsqcup"
    "\\oint"
    "\\bigotimes"
    "\\bigcap"
    "\\bigvee"
    "\\oint"
    "\\bigwedge"
    "\\biguplus"
    "\\bigodot"
    "\\coprod"
    "\\prod"
  ]

  SumsAndIntegrals = SumsAndIntegrals.map((word) ->
      caption: word + "{n}{i=..}{..}",
      snippet: word + "^{${1:n}}_{${2:i=1}}{${3}}"
      score: 1
      meta: "Sums and integrals"
  )


  formulasSnippets = [
    {
      caption: "\\frac{num}{denom}"
      snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
      score: 4
      meta: "Math"
    }
    {
      caption: "\\sqrt{n}"
      snippet: """
                \\sqrt{${1:n}}
            """
      score: 4
      meta: "Math"
    }
    {
      caption: "\\sqrt[k]{n}"
      snippet: """
                \\sqrt[${1:k}]{${2:n}}
            """
      score: 4
      meta: "Math"
    }
    {
      caption: "\\binom{n}{k}"
      snippet: """
                \\binom{${1:n}}{${2:k}}
            """
      score: 4
      meta: "Math"
    }
  ]


  greekLetters = [
    "\\gamma"
    "\\delta"
    "\\theta"
    "\\lambda"
    "\\nu"
    "\\xi"
    "\\pi"
    "\\sigma"
    "\\upsilon"
    "\\phi"
    "\\chi"
    "\\psi"
    "\\omega"
  ]

  greekLetters = greekLetters.concat(greekLetters.map((word) ->  return "\\" + word[1].toUpperCase() + word.substring(2)))
  greekLetters = greekLetters.concat([
    "\\alpha"
    "\\beta"
    "\\chi"
    "\\nu"
    "\\eta"
    "\\zeta"
    "\\rho"
    "\\mu"
    "\\epsilon"
    "\\iota"
    "\\kappa"
    "\\tau"
    "\\varepsilon"
    "\\varsigma"
    "\\varphi"
    "\\varrho"
    "\\vartheta"
    "\\varkappa"
  ])

  greekLetters = greekLetters.map((word) ->
    caption: word,
    value: word
    score: 2
    meta: "Greek Letter"
  )

  return SumsAndIntegrals.concat(formulasSnippets.concat(greekLetters))
);





