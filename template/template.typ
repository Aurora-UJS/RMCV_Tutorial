#import "@preview/ctheorems:1.1.3": thmenv, thmrules
#import "@preview/showybox:2.0.3": showybox


// Workaround for the lack of an `std` scope.
#let std-bibliography = bibliography
#let std-smallcaps = smallcaps
#let std-upper = upper

// Overwrite the default `smallcaps` and `upper` functions with increased spacing between
// characters. Default tracking is 0pt.
#let smallcaps(body) = std-smallcaps(text(tracking: 0.6pt, body))
#let upper(body) = std-upper(text(tracking: 0.6pt, body))

// Colors used across the template.
#let stroke-color = luma(200)
#let fill-color = luma(250)

// Commonly used mathematical constants / functions
#let iu = math.upright("i")
#let ddot(it) = math.dot.double(it)
#let vb(it) = math.bold(math.upright(it))
#let dcases(..args) = math.cases(..args.pos().map(math.display), ..args.named())

#let num_eq(it) = math.equation(
  block: true,
  numbering: (..num) => numbering("(1.1)", counter(heading).get().first(), num.pos().first()),
  it,
)

// This function gets your whole document as its `body`.
#let ilm(
  // The title for your work.
  title: [Your Title],
  // Author's name.
  author: "Author",
  // The paper size to use.
  paper-size: "a4",
  // Date that will be displayed on cover page.
  // The value needs to be of the 'datetime' type.
  // More info: https://typst.app/docs/reference/foundations/datetime/
  // Example: datetime(year: 2024, month: 03, day: 17)
  date: none,
  // Format in which the date will be displayed on cover page.
  // More info: https://typst.app/docs/reference/foundations/datetime/#format
  // The default format will display date as: MMMM DD, YYYY
  date-format: "[month repr:long] [day padding:zero], [year repr:full]",
  // An abstract for your work. Can be omitted if you don't have one.
  abstract: none,
  // The contents for the preface page. This will be displayed after the cover page. Can
  // be omitted if you don't have one.
  preface: none,
  // The result of a call to the `outline` function or `none`.
  // Set this to `none`, if you want to disable the table of contents.
  // More info: https://typst.app/docs/reference/model/outline/
  table-of-contents: outline(),
  // Display an appendix after the body but before the bibliography.
  appendix: (
    enabled: false,
    title: "",
    heading-numbering-format: "",
    body: none,
  ),
  // The result of a call to the `bibliography` function or `none`.
  // Example: bibliography("refs.bib")
  // More info: https://typst.app/docs/reference/model/bibliography/
  bibliography: none,
  // Whether to start a chapter on a new page.
  chapter-pagebreak: true,
  // Whether to display a maroon circle next to external links.
  external-link-circle: true,
  // Display an index of figures (images).
  figure-index: (
    enabled: false,
    title: "",
  ),
  // Display an index of tables
  table-index: (
    enabled: false,
    title: "",
  ),
  // Display an index of listings (code blocks).
  listing-index: (
    enabled: false,
    title: "",
  ),
  // The content of your work.
  body,
) = {
  // Set the document's metadata.
  set document(title: title, author: author)

  // show: show-cn-fakebold
  // show: remove-cjk-break-space

  set text(lang: "zh")
  set text(font: ("libertinus serif", "Times New Roman", "FZShuSong-Z01S", "Source Han Serif"))

  // Set the font used for CJK punctuation marks
  show regex("[。？！，、；：“”‘’『』「」（）〔〕【】─…—～·《》〈〉__]+"): set text(font: "Source Han Serif")

  show text.where(weight: "bold").or(strong): set text(font: (
    "libertinus serif",
    "Times New Roman",
    "Source Han Serif",
  ))

  // Set the body font.
  set text(size: 11pt) // default is 11pt

  // Set raw text font.
  // Default is Fira Mono at 8.8pt
  show raw: set text(font: ("Fira Mono","LXGW WenKai"))

  // Configure page size and margins.
  set page(paper: paper-size, margin: (bottom: 1.75cm, top: 2.25cm))

  // Cover page.
  page(align(left + horizon, block(width: 90%)[
    #let v-space = v(2em, weak: true)
    #text(size: 3em)[
      *#title*
    ]

    #v-space
    #text(1.6em, author)

    #if abstract != none {
      v-space
      block(width: 80%)[
        // Default leading is 0.65em.
        #par(leading: 0.78em, justify: true, linebreaks: "optimized", abstract)
      ]
    }

    #if date != none {
      v-space
      text(date.display(date-format))
    }
  ]))

  // Configure paragraph properties.
  // Default leading is 0.65em.
  // Default spacing is 1.2em.
  set par(
    leading: 0.8em,
    spacing: 1.0em,
    first-line-indent: (amount: 2em, all: true),
    justify: true,
    linebreaks: "optimized",
  )

  // Remove first-line-indent in lists
  // show list: set par(first-line-indent: (amount: 0pt, all: false))

  // Add vertical space after headings.
  show heading: it => {
    v(1.65em, weak: true)
    it
    v(1.25em, weak: true)
  }
  // Do not hyphenate headings.
  show heading: set text(hyphenate: false)

  // Display preface as the second page.
  if preface != none {
    page(preface)
  }

  // Display table of contents.
  if table-of-contents != none {
    table-of-contents
  }

  // Configure page numbering and footer.
  set page(footer: context {
    // Get current page number.
    let i = counter(page).at(here()).first()

    // Align right for even pages and left for odd.
    let is-odd = calc.odd(i)
    let aln = if is-odd {
      right
    } else {
      left
    }

    // Are we on a page that starts a chapter?
    let target = heading.where(level: 1)
    if query(target).any(it => it.location().page() == i) {
      return align(aln)[#i]
    }

    // Find the chapter of the section we are currently in.
    let before = query(target.before(here()))
    if before.len() > 0 {
      let current = before.last()
      let gap = 1.75em
      let chapter = upper(text(size: 0.68em, current.body))
      if current.numbering != none {
        if is-odd {
          align(aln)[#chapter #h(gap) #i]
        } else {
          align(aln)[#i #h(gap) #chapter]
        }
      }
    }
  })

  // Breakable & always 100% width (in list) equation.
  show math.equation: set block(breakable: true)
  show math.equation.where(block: true): eq => {
    block(width: 100%, inset: 0pt, align(center, eq))
  }

  // More gap in cases
  set math.cases(gap: 0% + 0.6em)

  // Break large tables across pages.
  show figure.where(kind: table): set block(breakable: true)
  set table(
    // Increase the table cell's padding
    inset: 7pt, // default is 5pt
    stroke: (0.5pt + stroke-color),
  )
  // Use smallcaps for table header row.
  show table.cell.where(y: 0): smallcaps

  // Wrap `body` in curly braces so that it has its own context. This way show/set rules
  // will only apply to body.
  {
    // Configure heading numbering.
    set heading(numbering: "1.")

    // Start chapters on a new page.
    show heading.where(level: 1): it => {
      if chapter-pagebreak {
        pagebreak(weak: true)
      }
      it
    }

    let typst_builtin_sequence = ([A] + [ ] + [B]).func()
    let typst_builtin_space = [ ].func()

    // Automatically stick paragraph to block equation (Testing)
    let stick_paragraph(it) = {
      if type(it) == content and it.func() == typst_builtin_sequence {
        let para = none

        for child in it.children {
          if child.func() in (text, typst_builtin_space, ref, footnote, h, math.equation, strong) {
            if child.func() == math.equation and child.block {
              if para != none {
                if para == [ ] {
                  para
                } else {
                  block(sticky: true, parbreak() + para)
                }
                para = none
              }
              child
            } else {
              para += child
            }
          } else {
            para
            stick_paragraph(child)
            para = none
          }
        }
        para
      } else {
        it
      }
    }
    show: stick_paragraph

    body
  }

  // Display appendix before the bibliography.
  if appendix.enabled {
    pagebreak()
    heading(level: 1)[#appendix.at("title", default: "Appendix")]

    // For heading prefixes in the appendix, the standard convention is A.1.1.
    let num-fmt = appendix.at("heading-numbering-format", default: "A.1.1.")

    counter(heading).update(0)
    set heading(outlined: false, numbering: (..nums) => {
      let vals = nums.pos()
      if vals.len() > 0 {
        let v = vals.slice(0)
        return numbering(num-fmt, ..v)
      }
    })

    appendix.body
  }

  // Display bibliography.
  if bibliography != none {
    pagebreak()
    show std-bibliography: set text(0.85em)
    // Use default paragraph properties for bibliography.
    show std-bibliography: set par(leading: 0.65em, justify: false, linebreaks: auto)
    bibliography
  }

  // Display indices of figures, tables, and listings.
  let fig-t(kind) = figure.where(kind: kind)
  let has-fig(kind) = counter(fig-t(kind)).get().at(0) > 0
  if figure-index.enabled or table-index.enabled or listing-index.enabled {
    show outline: set heading(outlined: true)
    context {
      let imgs = figure-index.enabled and has-fig(image)
      let tbls = table-index.enabled and has-fig(table)
      let lsts = listing-index.enabled and has-fig(raw)
      if imgs or tbls or lsts {
        // Note that we pagebreak only once instead of each each individual index. This is
        // because for documents that only have a couple of figures, starting each index
        // on new page would result in superfluous whitespace.
        pagebreak()
      }

      if imgs {
        outline(title: figure-index.at("title", default: "Index of Figures"), target: fig-t(image))
      }
      if tbls {
        outline(title: table-index.at("title", default: "Index of Tables"), target: fig-t(table))
      }
      if lsts {
        outline(title: listing-index.at("title", default: "Index of Listings"), target: fig-t(raw))
      }
    }
  }
}



// Configure blockquotes.
#let blockquote(cite: none, body) = [
  #set text(size: 0.97em)
  #pad(left: 1.5em)[
    #block(
    breakable: true,
    width: 100%,
    fill: gray.lighten(90%),
    radius: (left: 0pt, right: 5pt),
    stroke: (left: 5pt + gray, rest: 1pt + silver),
    inset: 1em
    )[#body]
  ]
]


// Configure horizontal ruler
#let horizontalrule = {
  v(1em)
  line(start: (37%,0%), end: (63%,0%), stroke: stroke((thickness: 0.5pt, dash: "solid")))
  v(1em)
}

// Configure alternative horizontal ruler
#let sectionline = align(center)[#v(0.5em) * \* #sym.space.quad \* #sym.space.quad \* * #v(0.5em)]

// Attempt to add \boxed{} command from LaTeX
#let dboxed(content) =  {
    box(stroke: 0.5pt + black, outset: (x: 1pt, y: 8pt), inset: (x: 2pt, y: 1pt), baseline: 6pt, $display(#content)$)
  } 
  
#let iboxed(content) = {
    box(stroke: 0.5pt + black, outset: (x: 1pt, y: 3pt), inset: (x: 2pt, y: 1pt), baseline: 1pt, $#content$)
  }

// ==== Nice boxes using showybox and ctheorems packages ====
//
// | Environment | Accent Color         |
// |-------------|----------------------|
// | Definition  | olive                |
// | Example     | purple               |
// | Note        | blue                 |
// | Attention   | red / rgb("#DC143C") |
// | Quote       | black                |
// | Theorem     | navy                 |  
// | Proposition | maroon               |
// | Hypothesis  | orange               |

#let boxnumbering = "1.1.1.1.1.1"
#let boxcounting = "heading"

#let definition = thmenv(
  "Definition",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Definition #number],
      frame: (
        border-color: olive,
        title-color:  olive.lighten(30%),
        body-color:   olive.lighten(95%),
        footer-color: olive.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let example = thmenv(
  "example",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Example #number],
      frame: (
        border-color: purple,
        title-color:  purple.lighten(30%),
        body-color:   purple.lighten(95%),
        footer-color: purple.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let note = thmenv(
  "note",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Note #number],
      frame: (
        border-color: blue,
        title-color:  blue.lighten(30%),
        body-color:   blue.lighten(95%),
        footer-color: blue.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let attention = thmenv(
  "attention",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Attention #number],
      frame: (
        border-color: rgb("#DC143C"),
        title-color:  rgb("#DC143C").lighten(30%),
        body-color:   rgb("#DC143C").lighten(95%),
        footer-color: rgb("#DC143C").lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let quote = thmenv(
  "quote",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Quote #number],
      frame: (
        border-color: black,
        title-color:  black.lighten(30%),
        body-color:   black.lighten(95%),
        footer-color: black.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let theorem = thmenv(
  "theorem",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Theorem #number],
      frame: (
        border-color: navy,
        title-color:  navy.lighten(30%),
        body-color:   navy.lighten(95%),
        footer-color: navy.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)

#let proposition = thmenv(
  "Proposition",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Proposition #number],
      frame: (
        border-color: maroon,
        title-color:  maroon.lighten(30%),
        body-color:   maroon.lighten(95%),
        footer-color: maroon.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)


#let hypothesis = thmenv(
  "hypothesis",
  boxcounting,
  none,
  (name, number, body, ..args) => {
    showybox(
      title: [*#name* #h(1fr) Hypothesis #number],
      frame: (
        border-color: orange,
        title-color:  orange.lighten(10%),
        body-color:   orange.lighten(95%),
        footer-color: orange.lighten(80%),
      ),
      ..args.named(),
      body
    )
  }
).with(numbering: boxnumbering)
