defmodule Post do
  defstruct [
    :id,
    :path_from_root,
    :path_for_render,
    :dt,
    :has_content,
    :manifest
  ]

  def ready?(%{manifest: nil}), do: false
  def ready?(%{manifest: %{parsed: nil}}), do: false
  def ready?(%{has_content: false}), do: false
  def ready?(%{manifest: %{parsed: _}, has_content: true}), do: true

  @content_html "post.html"
  @content_file @content_html <> ".heex"
  @posts_path_for_render "posts/"
  @posts_path_from_root Path.join("lib/blog_web/templates/page/", @posts_path_for_render)

  def load_all do
    {:ok, posts} = File.ls(@posts_path_from_root)
    IO.puts("Potential posts: " <> inspect(posts))
    posts |> Enum.map(&load_post/1)
  end

  def load_post(dir_name) do
    path_from_root = Path.join(@posts_path_from_root, dir_name)

    parse_datetime = fn str -> 
      case Timex.parse(str, "{D}_{M}_{YY}") do
        {:ok, dt} ->
          dt

        {:error, _} ->
          case Timex.parse(str, "{D}_{M}_{YY} {h24}:{m}") do
            {:ok, dt} -> dt
            {:error, _} -> raise "invalid post time: " <> str
          end
      end
    end

    %Post{
      id: dir_name, # post ID is the date is the directory name
      dt: parse_datetime.(dir_name),
      path_from_root: path_from_root,
      path_for_render: Path.join([@posts_path_for_render, dir_name, @content_html]),
      has_content: File.exists?(Path.join(path_from_root, @content_file)),
      manifest: Post.Manifest.load(path_from_root)
    }
  end
end
