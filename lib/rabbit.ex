defmodule Rabbit do
  alias Chisel.Font
  alias Chisel.Renderer

  def draw_text(text) do
    {:ok, font} = Chisel.Font.load("/lib/fonts/5x8.bdf")

    Chisel.Renderer.draw_text(text, 50, 50, font, fn x, y ->
      Rabbit.Display.put_pixel(x, y)
    end)
  end

  def render_message(message) do
    Rabbit.Display.clear()
    draw_text(message)
    Rabbit.Display.display()
  end

  def debug() do
    Rabbit.Display.clear()
    # Draw something
    Rabbit.Display.rect(0, 0, 127, 31)
    Rabbit.Display.line(0, 0, 127, 31)
    Rabbit.Display.line(0, 31, 127, 0)

    # Display it!
    Rabbit.Display.display()
  end
end
