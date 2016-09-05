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

  compare = (a, b) -> a.localeCompare(b)
  SUMS_AND_INTEGRALS = SUMS_AND_INTEGRALS.sort(compare)
  SUMS_AND_INTEGRALS = for i in [0..SUMS_AND_INTEGRALS.length-1]
      caption: SUMS_AND_INTEGRALS[i] + "{n}{i=..}{..}"
      snippet: SUMS_AND_INTEGRALS[i] + "^{${1:n}}_{${2:i=1}}{${3}}"
      score: 1000 - i
      meta: "Sums and integrals"
      meta_score: 1000


  MATH_SNIPPETS = [
    {
      caption: "\\frac{num}{denom}"
      snippet: """
                \\frac{${1:num}}{${2:denom}}
            """
    }
    {
      caption: "\\sqrt{n}"
      snippet: """
                \\sqrt{${1:n}}
            """
    }
    {
      caption: "\\sqrt[k]{n}"
      snippet: """
                \\sqrt[${1:k}]{${2:n}}
            """
    }
    {
      caption: "\\binom{n}{k}"
      snippet: """
                \\binom{${1:n}}{${2:k}}
            """
    }
  ]

  MATH_SNIPPETS = MATH_SNIPPETS.sort((a, b) -> a.caption.localeCompare(b.caption))
  MATH_SNIPPETS = for i in [0..MATH_SNIPPETS.length-1]
      caption: MATH_SNIPPETS[i].caption
      snippet: MATH_SNIPPETS[i].snippet
      score: 1000 - i
      meta: "Math"
      meta_score: 10


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

  GREEK_LETTERS = GREEK_LETTERS.sort(compare)
  GREEK_LETTERS = for i in [0..GREEK_LETTERS.length]
    caption: GREEK_LETTERS[i]
    value: GREEK_LETTERS[i]
    score: 1000 - i
    meta: "Greek Letter"
    meta_score: 2


  return SUMS_AND_INTEGRALS.concat(MATH_SNIPPETS, GREEK_LETTERS)
);