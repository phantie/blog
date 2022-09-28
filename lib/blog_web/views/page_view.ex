defmodule BlogWeb.PageView do
  use BlogWeb, :view
  use Phoenix.Component
  use Phoenix.HTML, :raw

  def text(assigns) do
    ~H"""
    <section>
      <div class="text"><%= render_slot(@inner_block) %></div>
    </section>
    """
  end

  def link(assigns) do
    ~H"""
      <a class="link" href={@href}><%= render_slot(@inner_block) %></a>ᴴ
    """
  end

  def ref_text(assigns) do
    ~H"""
    <section class="ref_text">
      <div class="quote">“</div>
      <div class="text">
        <%= render_slot(@inner_block) %>
      </div>
      <div class="quote">”</div>
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
      <iframe src={@url} allowfullscreen>
      </iframe>
    </section>
    """
  end

  # TODO add support for local images stored closely to post files
  def img(assigns) do
    ~H"""
    <section class="img">
      <img src={@url}>
    </section>
    """
  end

  def post_preview(assigns) do
    ~H"""
    <section class="post_preview">
      <h3><%= @title %></h3>
      <p><%= @desc %></p>
      <small><i><%= @tags %></i></small>
    </section>
    """
  end

  def post_previews(assigns) do
    valid_posts = Blog.Posts.value() |> Blog.Posts.valid_posts()

    posts =
      valid_posts
      |> Enum.sort_by(fn post -> post.dt end, {:desc, NaiveDateTime})
      |> Enum.map(fn post ->
        Map.take(post.manifest.parsed, [:title, :description, :tags])
        |> Map.put(
          :date,
          case Timex.format(post.dt, "{Mshort} {D}, {YYYY}") do
            {:ok, fmt} -> fmt
          end
        )
      end)

    assigns = Map.put(assigns, :posts, posts)

    ~H"""
      <%= for post <- @posts do %>
        <section class="post_preview">
          <div class="title"><%= post.title %></div>
          <div class="meta">
            <div class="date"><%= post.date %></div>
            <div class="tags">
              <%= for tag <- post.tags do %>
                <div class="tag">
                  <.link href="/"><%= tag %></.link>
                </div>
              <% end %>
            </div>
          </div>
          <div class="description"><%= post.description %></div>
        </section>
      <% end %>
    """
  end
end
