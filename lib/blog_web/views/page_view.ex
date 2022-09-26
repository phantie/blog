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
    assigns =
      assigns
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

  defp add_query(url, query_params) do
    (url <> "?") <>
      (query_params
       |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
       |> Enum.join("&"))
  end

  def yt(assigns) do
    assigns =
      assigns
      |> Map.delete(:id)
      |> Map.put(:url, "https://youtube.com/embed/#{assigns.id}")

    query = [modestbranding: 1]

    assigns = assigns |> Map.put(:url, add_query(assigns.url, query))

    ~H"""
    <section class="yt_video">
      <iframe src={@url}>
      </iframe>
    </section>
    """
  end
end
