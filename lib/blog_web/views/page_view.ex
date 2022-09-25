defmodule BlogWeb.PageView do
  use BlogWeb, :view
  use Phoenix.Component
  use Phoenix.HTML, :raw

  def text(assigns) do
    ~H"""
    <section>
    <div class="text"><%= @text %></div>
    </section>
    """
  end

  def ref_text(assigns) do
    ~H"""
    <section class="ref_text">
    <div class="text"><%= @text %></div>
    <div class="ref"><%= @ref %></div>
    </section>
    """
  end
end
