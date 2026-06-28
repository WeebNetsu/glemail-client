import frontend/component
import lustre/element
import lustre/element/html

pub fn view() -> List(element.Element(a)) {
  [component.div(attributes: [], elements: [html.text("Not Found")])]
}
