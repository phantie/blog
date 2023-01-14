defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  # generate a test for every "valid" blog post and try to render each
  for id <- Map.keys(Blog.Posts.id_to_valid_post()) do
    @url "/post/#{id}/"
    test "GET #{@url}", %{conn: conn} do
      assert get(conn, @url).status == 200
    end
  end

  defp render_posts_pages(conn, page) do
    status =
      get(conn, Routes.page_path(conn, :posts) |> BlogWeb.PageView.join_query(%{page: page})).status

    case status do
      200 -> render_posts_pages(conn, page + 1)
      404 -> nil
      _ -> raise "error on page #{page}"
    end
  end

  test "GET post list pages", %{conn: conn} do
    render_posts_pages(conn, 1)
  end

  # render every post to register links that they have for testing
  defp render_every_post(conn) do
    for id <- Map.keys(Blog.Posts.id_to_valid_post()) do
      get(conn, "/post/#{id}/")
    end
  end

  test "ping local links", %{conn: conn} do
    Blog.Test.Links.clear()

    render_every_post(conn)

    links = Blog.Test.Links.local_urls()

    broken_links =
      links
      |> Enum.map(fn url -> {url, head(conn, url).status} end)
      |> Enum.filter(fn {_url, status} -> status != 200 end)

    IO.puts("tested links: #{Enum.count(links)}")

    assert Enum.empty?(broken_links), "broken links: \n#{inspect(broken_links, pretty: true)}"
  end
end
