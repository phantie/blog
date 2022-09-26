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

  def code(assigns) do
    # TODO finish support of possibly undetected languages
    # assigns = case assigns[:lang] do
    #   nil -> Map.put(assigns, :lang, "") # autodetect
    #   lang -> Map.put(assigns, :lang, "class=\"#{lang}\"")
    # end

    assigns =
      if assigns[:file] do
        nil = assigns[:code]
        {:ok, code} = File.read(assigns[:file])
        Map.put(assigns, :code, code)
      else
        assigns
      end

    ~H"""
    <section class="code">
      <pre><code><%= @code %></code></pre>
    </section>
    """
  end

  def title(assigns) do
    ~H"""
    <section class="title">
      <%= @title %>
    </section>
    """
  end

  def yt(assigns) do
    assigns =
      if assigns[:id] do
        nil = assigns[:url]
        Map.put(assigns, :url, "https://youtube.com/embed/#{assigns.id}")
      else
        assigns
      end

    assigns = Map.put(assigns, :url, assigns.url <> "?modestbranding=1")

    ~H"""
    <section class="yt_video">
      <iframe src={@url}>
      </iframe>
    </section>
    """
  end
end
