defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def index(conn, _params) do
    conn
    |> render("index.html")
  end

  def first_post(conn, _params) do
    conn
    |> render("posts/26_9_22/post.html", page_title: "Post")
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

  def posts(conn, params) do
    page =
      case params["page"] do
        nil ->
          1

        page ->
          case Integer.parse(page) do
            {int, ""} when int > 0 -> int
            _ -> 1
          end
      end

    posts = case params["tag"] do
      nil -> Blog.Posts.posts_for_display()
      tag -> Blog.Posts.tag_to_valid_posts_for_display()[tag] || []
    end

    posts_per_page = 1

    posts_page = posts |> Blog.Posts.take_page(page, posts_per_page)

    next_page_exists = Blog.Posts.post_page_exists?(posts, page + 1, posts_per_page: posts_per_page)

    conn
    |> render(
      "posts.html",
      page_title: "Posts",
      posts: posts_page,
      page: page,
      posts_per_page: posts_per_page,
      tag: params["tag"],
      next_page_exists: next_page_exists
    )
  end

  def post(conn, %{"id" => id}) do
    case Blog.Posts.valid_post_by_id(id) do
      nil -> conn |> send_resp(404, "")
      post -> render(conn, post.path_for_render, page_title: "Post")
    end
  end
end
