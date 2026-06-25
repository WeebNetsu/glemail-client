import gleam/io
import lustre/attribute
import lustre/element
import lustre/element/html

pub fn div(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
) -> element.Element(a) {
  html.div([attribute.class("flex gap-2 flex-col"), ..attributes], elements)
}

pub fn button(
  attributes attributes: List(attribute.Attribute(a)),
  elements elements: List(element.Element(a)),
  variant variant: String,
) -> element.Element(a) {
  let default_variant_style =
    "bg-primary text-gray-900 shadow-xs hover:bg-primary/90"

  let additional_classes = case variant {
    "destructive" -> {
      "bg-destructive text-white shadow-xs hover:bg-destructive/90 focus-visible:ring-destructive/20 dark:focus-visible:ring-destructive/40 dark:bg-destructive/60"
    }
    "default" -> default_variant_style
    _ -> {
      io.println_error("No variant of '" <> variant <> "' exists on button")
      default_variant_style
    }
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
