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
    assigns = assigns
      |> Map.put(
        :lang,
        case assigns[:lang] do
          # autodetect
          nil -> ""
          lang -> "language-#{lang}"
        end
      )

    assigns =
      if assigns[:file] do
        nil = assigns[:code]
        {:ok, code} = File.read(assigns[:file])
        assigns
        |> Map.delete(:file)
        |> Map.put(:code, code)
      else
        assigns
      end

    ~H"""
    <section class="code">
      <pre><code class={@lang}><%= @code %></code></pre>
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
        assigns
        |> Map.delete(:id)
        |> Map.put(:url, "https://youtube.com/embed/#{assigns.id}")
      else
        assigns
      end

    assigns = assigns |> Map.put(:url, assigns.url <> "?modestbranding=1")

    ~H"""
    <section class="yt_video">
      <iframe src={@url}>
      </iframe>
    </section>
    """
  end
end
