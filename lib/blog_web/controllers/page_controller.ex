defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def index(conn, _params) do
    # conn
    # |> render("index.html")
    redirect(conn, to: "/posts/")
  end

  def posts_per_page do
    10
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

    posts =
      case params["tag"] do
        nil -> Blog.Posts.posts_for_display()
        tag -> Blog.Posts.tag_to_valid_posts_for_display()[tag] || []
      end

    posts_page = posts |> Blog.Posts.take_page(page, posts_per_page())

    next_page_exists =
      Blog.Posts.post_page_exists?(posts, page + 1, posts_per_page: posts_per_page())

    case Enum.count(posts_page) do
      0 ->
        conn |> put_status(:not_found)

      _ ->
        conn
        |> render(
          "posts.html",
          page_title: "Posts",
          posts: posts_page,
          page: page,
          posts_per_page: posts_per_page(),
          tag: params["tag"],
          next_page_exists: next_page_exists
        )
    end
  end

  def post(conn, %{"id" => id}) do
    case Blog.Posts.valid_post_by_id(id) do
      nil ->
        conn |> send_resp(404, "")

      post ->
        render(
          conn,
          post.path_for_render,
          page_title: Post.title(post),
          title: Post.title(post),
          code_path: Post.code_path(post)
        )
    end
  end
end
