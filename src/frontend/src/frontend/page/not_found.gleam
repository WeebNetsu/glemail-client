import frontend/components
import lustre/element
import lustre/element/html

pub fn view() -> List(element.Element(a)) {
  [components.div(attributes: [], elements: [html.text("Not Found")])]
}
