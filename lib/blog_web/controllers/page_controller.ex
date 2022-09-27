defmodule BlogWeb.PageController do
  use BlogWeb, :controller

  def index(conn, _params) do
    conn
    |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    |> put_flash(:error, "Let's pretend we have an error.")
    |> render("index.html")
  end

  def post(conn, _params) do
    conn
    # |> put_flash(:info, "Welcome to Phoenix, from flash info!")
    # |> put_flash(:error, "Let's pretend we have an error.")
    |> render("posts/26_9_22/post.html", page_title: "Post")
  end

  def posts(conn, _params) do
    conn
    |> render("posts.html", page_title: "Posts")
  end
end
