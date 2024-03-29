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
    if Mix.env() == :test do
      Blog.Test.Links.add(assigns.href)
    end

    params = %{"href" => assigns.href}

    params =
      case assigns[:title] do
        nil -> params
        title -> Map.put(params, "title", title)
      end

    assigns = Map.put(assigns, :params, params)

    ~H"""
      <a class="link" {@params}><%= render_slot(@inner_block) %></a><div
        class="href_sign">ᴴ</div>
    """
  end

  def ref_text(assigns) do
    ~H"""
    <section class="ref_text">
      <div class="text_block">
        <div class="quote_symbol">“</div>
        <div class="text">
          <%= render_slot(@inner_block) %>
        </div>
        <div class="quote_symbol">”</div>
      </div>
      <div class="ref"><%= @ref %></div>
    </section>
    """
  end

  defp set_code_lang(assigns) do
    Map.put(
      assigns,
      :lang,
      case assigns[:lang] do
        # autodetect
        nil -> ""
        lang -> "language-#{lang}"
      end
    )
  end

  defp set_code_lang(assigns, file_path) do
    assigns = set_code_lang(assigns)

    ext_to_lang = %{
      ".py" => "python",
      ".rs" => "rust",
      ".js" => "javascript",
      ".clj" => "clojure"
    }

    case Path.extname(file_path) do
      "" ->
        assigns

      ext ->
        case Map.has_key?(ext_to_lang, ext) do
          true ->
            case assigns.lang do
              "" ->
                nil

              _lang ->
                if Mix.env() == :dev do
                  raise "language detected using extension of file: #{file_path}"
                end
            end

            Map.put(assigns, :lang, "language-#{ext_to_lang[ext]}")

          false ->
            assigns
        end
    end
  end

  def code_file(assigns) do
    file = Path.join(assigns.code_path, assigns.file)
    assigns = set_code_lang(assigns, file)
    {:ok, code} = File.read(file)

    assigns =
      assigns
      |> Map.delete(:file)
      |> Map.put(:code, code)

    ~H"""
    <section class="code">
      <pre><code class={@lang}><%= @code %></code></pre>
    </section>
    """
  end

  # TODO find a way to remove the first line if empty
  def code(assigns) do
    assigns = set_code_lang(assigns)

    ~H"""
    <section class="code">
      <pre><code class={@lang}><%= render_slot(@inner_block) %></code></pre>
    </section>
    """
  end

  def title(assigns) do
    ~H"""
    <section class="title">
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  def section_title(assigns) do
    params =
      case assigns[:id] do
        nil -> %{}
        id -> %{"id" => id}
      end

    assigns = Map.put(assigns, :params, params)

    ~H"""
    <section class="section_title" {@params}>
      <%= render_slot(@inner_block) %>
    </section>
    """
  end

  def yt(assigns) do
    url = "https://youtube.com/embed/#{assigns.id}"

    if Mix.env() == :test do
      Blog.Test.Links.add(url)
    end

    assigns =
      assigns
      |> Map.delete(:id)
      |> Map.put(:url, url)

    query = %{"modestbranding" => 1}

    assigns = assigns |> Map.put(:url, join_query(assigns.url, query))

    ~H"""
    <section class="yt_video">
      <iframe src={@url} allowfullscreen>
      </iframe>
    </section>
    """
  end

  def img(assigns) do
    if Mix.env() == :test do
      Blog.Test.Links.add(assigns.url)
    end

    ~H"""
    <section class="img">
      <img src={@url}>
    </section>
    """
  end

  # TODO improve experience
  def img_local(assigns) do
    if Mix.env() == :test do
      Blog.Test.Links.add(assigns.url)
    end

    ~H"""
    <section class="img">
      <img src={ Routes.static_path(@conn, @url) }>
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

  def join_query(url, query) when query == %{}, do: url
  def join_query(url, %{} = query), do: url <> "?" <> URI.encode_query(query)

  def post_next_page_query(%{page: page, tag: tag}) do
    q = %{}

    q =
      case page do
        0 -> q
        page -> Map.put(q, "page", page + 1)
      end

    q =
      case tag do
        nil -> q
        tag -> Map.put(q, "tag", tag)
      end

    join_query("/posts/", q)
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
                    <.link
                    href={post_next_page_query(%{page: 0, tag: tag})}
                    title="Filter posts by tag"><%= tag %></.link>
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
