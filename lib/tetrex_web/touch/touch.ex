defmodule TetrexWeb.Touch do
  defstruct [
    :identifier,
    :screen_x,
    :screen_y,
    :client_x,
    :client_y,
    :page_x,
    :page_y,
    :target_dom_element,
    :area_radius_x,
    :area_radius_y,
    :area_rotation_angle,
    :force
  ]

  def from_js_touch(%{
        "identifier" => identifier,
        "screenX" => screen_x,
        "screenY" => screen_y,
        "clientX" => client_x,
        "clientY" => client_y,
        "pageX" => page_x,
        "pageY" => page_y,
        "target" => target_dom_element,
        "radiusX" => area_radius_x,
        "radiusY" => area_radius_y,
        "rotationAngle" => area_rotation_angle,
        "force" => force
      }),
      do: %__MODULE__{
        identifier: identifier,
        screen_x: screen_x,
        screen_y: screen_y,
        client_x: client_x,
        client_y: client_y,
        page_x: page_x,
        page_y: page_y,
        target_dom_element: target_dom_element,
        area_radius_x: area_radius_x,
        area_radius_y: area_radius_y,
        area_rotation_angle: area_rotation_angle,
        force: force
      }

  def quadrant_direction(%__MODULE__{area_rotation_angle: angle})
      when 0 <= angle and angle <= 360 do
    cond do
      0 <= angle and angle < 90 -> :left
      90 <= angle and angle < 180 -> :up
      180 <= angle and angle < 270 -> :right
      270 <= angle -> :down
    end
  end
end
