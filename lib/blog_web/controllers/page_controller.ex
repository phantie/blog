defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    |> render("index.html")
  end

  def first_post(conn, _params) do
    conn
    |> render("posts/26_9_22/post.html", page_title: "Post")
  end

  def posts(conn, params) do
    desired_page =
      case params["page"] do
        nil ->
          1

        page ->
          case Integer.parse(page) do
            {int, ""} when int > 0 -> int
            _ -> 1
          end
      end

    conn
    |> render("posts.html",
      page_title: "Posts",
      page: desired_page
    )
  end

  def post(conn, %{"id" => id}) do
    case Blog.Posts.post_by_id(id) do
      nil -> conn |> send_resp(404, "")
      post -> render(conn, post.path_for_render, page_title: "Post")
    end
  end
end
