define((require, exports, module) ->

  SUMS_AND_INTEGRALS = [
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

  SUMS_AND_INTEGRALS = SUMS_AND_INTEGRALS.map((word) ->
      caption: word + "{n}{i=..}{..}",
      snippet: word + "^{${1:n}}_{${2:i=1}}{${3}}"
      score: 1000 - word.charCodeAt(1)
      meta: "Sums and integrals"
  )


  FORMULAS_SNIPPETS = [
    {
      caption: "\\frac{num}{denom}"
      snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
      score: 2
      meta: "Math"
    }
    {
      caption: "\\sqrt{n}"
      snippet: """
                \\sqrt{${1:n}}
            """
      score: 3
      meta: "Math"
    }
    {
      caption: "\\sqrt[k]{n}"
      snippet: """
                \\sqrt[${1:k}]{${2:n}}
            """
      score: 3
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


  GREEK_LETTERS = [
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

  capitalizeGreekLetter = (word) -> return "\\" + word[1].toUpperCase() + word.substring(2)
  GREEK_LETTERS = GREEK_LETTERS.concat(GREEK_LETTERS.map(capitalizeGreekLetter))
  GREEK_LETTERS = GREEK_LETTERS.concat([
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

  GREEK_LETTERS = GREEK_LETTERS.map((word) ->
    caption: word,
    value: word
    score: 1000 - word.charCodeAt(1)
    meta: "Greek Letter"
  )

  return SUMS_AND_INTEGRALS.concat(FORMULAS_SNIPPETS, GREEK_LETTERS)
);





