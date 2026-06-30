import gleam/option
import lustre/attribute
import lustre/element
import lustre/element/html

pub type Variants {
  DestructiveVariant
  DefaultVariant
}

/// regular `<p>` tag with custom styling to display errors
pub fn error_p(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
) -> element.Element(a) {
  html.p(
    [attribute.class("text-xs text-destructive italic"), ..attributes],
    elements,
  )
}

pub fn div(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
) -> element.Element(a) {
  html.div([attribute.class("flex gap-2 flex-col"), ..attributes], elements)
}

pub fn input(
  attributes attributes: List(attribute.Attribute(a)),
) -> element.Element(a) {
  html.input([
    attribute.class(
      "h-8 w-full min-w-0 rounded-2xl border border-transparent bg-input/50 px-2.5 py-1 text-base transition-[color,box-shadow] duration-200 outline-none 
      file:inline-flex file:h-6 file:border-0 file:bg-transparent file:text-sm file:font-medium file:text-foreground placeholder:text-muted-foreground focus-visible:border-ring
      focus-visible:ring-3focus-visible:ring-ring/30 disabled:pointer-events-none disabled:cursor-not-allowed disabled:opacity-50 aria-invalid:border-destructive aria-invalid:ring-3
      aria-invalid:ring-destructive/20 md:text-sm dark:aria-invalid:border-destructive/50 dark:aria-invalid:ring-destructive/40",
    ),
    ..attributes
  ])
}

pub fn button(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
  variant variant: Variants,
) -> element.Element(a) {
  let default_variant_style =
    "bg-primary text-gray-900 shadow-xs hover:bg-primary/90"

  let additional_classes = case variant {
    DestructiveVariant -> {
      "bg-destructive text-white shadow-xs hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60"
    }
    DefaultVariant -> default_variant_style
  }

  html.button(
    [
      attribute.class(
        "inline-flex items-center justify-center gap-2 whitespace-nowrap rounded-md text-sm font-medium transition-all disabled:pointer-events-none disabled:opacity-50 
        [&_svg]:pointer-events-none [&_svg:not([class*='size-'])]:size-4 shrink-0 [&_svg]:shrink-0 outline-none focus-visible:border-ring focus-visible:ring-ring/50 
        focus-visible:ring-[3px] aria-invalid:ring-destructive/20 dark:aria-invalid:ring-destructive/40 aria-invalid:border-destructive cursor-pointer pl-1 pr-1 "
        <> additional_classes,
      ),
      ..attributes
    ],
    elements,
  )
}

pub fn card(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
  actions actions: List(element.Element(a)),
  title title: option.Option(String),
) {
  html.div(
    [
      attribute.class(
        "flex flex-col gap-2 justify-between bg-card text-card-foreground flex flex-col gap-6 rounded-xl border py-6 shadow-sm",
      ),
      ..attributes
    ],
    [
      html.div([attribute.class("h-full")], [
        case title {
          option.Some(label) ->
            html.div(
              [
                attribute.class(
                  "@container/card-header grid auto-rows-min grid-rows-[auto_auto] items-start gap-1.5 px-6 
                  has-data-[slot=card-action]:grid-cols-[1fr_auto] [.border-b]:pb-6",
                ),
              ],
              [
                html.div([attribute.class("leading-none font-semibold")], [
                  html.text(label),
                ]),
              ],
            )
          option.None -> html.div([], [])
        },

        html.div([attribute.class("h-full px-6")], elements),
      ]),
      html.div(
        [attribute.class("flex gap-1 flex items-center px-6 [.border-t]:pt-6")],
        actions,
      ),
    ],
  )
}
