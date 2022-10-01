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
      <a class="link" href={@href}><%= render_slot(@inner_block) %></a><div class="href_sign">ᴴ</div>
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
        # TODO refactor, not hardcoding path
        file = "lib/blog_web/templates/page/posts/" <> assigns[:file]
        {:ok, code} = File.read(file)

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

  def post_next_page_query(%{page: page, tag: tag} = query_params) do
    q = %{}

    q = case page do
      0 -> q
      page -> Map.put(q, "page", page + 1)
    end

    q = case tag do
      nil -> q
      tag -> Map.put(q, "tag", tag)
    end

    case q do
      q when q == %{} -> "/posts/"
      q -> "/posts/?" <> URI.encode_query(q)
    end
  end

  def post_previews(assigns) do
    ~H"""
      <%= for post <- @posts do %>
        <section class="post_preview">
          <div class="title">
            <.link href={"/post/" <> post.id <> "/"}><%= post.title %></.link>
          </div>
          <div class="meta">
            <div class="date"><%= post.date %></div>
            <div class="tags">
              <%= for tag <- post.tags do %>
                <div class="tag">
                  <.link href={post_next_page_query(%{page: 0, tag: tag})}><%= tag %></.link>
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
