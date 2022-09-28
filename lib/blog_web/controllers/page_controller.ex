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

  def posts(conn, _params) do
    conn
    |> render("posts.html", page_title: "Posts")
  end

  def post(conn, %{"id" => id}) do
    case Blog.Posts.post_by_id(id) do
      nil -> conn |> send_resp(404, "")
      post -> render(conn, post.path_for_render, page_title: "Post")
    end
  end
end
