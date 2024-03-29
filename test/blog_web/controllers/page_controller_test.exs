defmodule BlogWeb.PageControllerTest do
  use BlogWeb.ConnCase

  # generate a test for every "valid" blog post and try to render each
  for id <- Map.keys(Blog.Posts.id_to_valid_post()) do
    @id id
    test "render post #{@id}", %{conn: conn} do
      page = render_post(conn, @id)
      assert page.status == 200
    end
  end

  test "GET post list pages", %{conn: conn} do
    render_posts_pages(conn, 1)
  end

  test "ping local links", %{conn: conn} do
    Blog.Test.Links.clear()
    render_every_post(conn)
    links = Blog.Test.Links.local()

    broken_links =
      links
      |> Enum.map(fn url -> {url, head(conn, url).status} end)
      |> Enum.filter(fn {_url, status} -> status != 200 end)

    IO.puts("tested local links: #{Enum.count(links)}")

    assert Enum.empty?(broken_links), "broken links: \n#{inspect(broken_links, pretty: true)}"
  end

  @tag :online
  test "ping external links", %{conn: conn} do
    Blog.Test.Links.clear()
    render_every_post(conn)
    links = Blog.Test.Links.external()

    # TODO fix requests for urls with query params, make 400 invalid code to receive

    broken_links =
      links
      |> Enum.map(fn url -> {url, elem(HTTPoison.head(url, [], follow_redirect: true), 1).status_code} end)
      |> Enum.filter(fn {_url, status} -> status not in [200, 400] end)

    IO.puts("tested external links: #{Enum.count(links)}")

    assert Enum.empty?(broken_links), "broken links: \n#{inspect(broken_links, pretty: true)}"
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

  defp render_post(conn, id) do
    get(conn, "/post/#{id}/")
  end

  # render every post to register links that they have for testing
  defp render_every_post(conn) do
    Blog.Posts.id_to_valid_post()
    |> Map.keys()
    |> Enum.map(fn id -> render_post(conn, id) end)
  end
end
