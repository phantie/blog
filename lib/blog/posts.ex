defmodule Post do
  defstruct [
    :path,
    :dt,
    :has_content,
    :manifest
  ]

  def parse_datetime(str) do
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
end

defmodule Post.Manifest do
  defstruct path: nil,
            content: nil,
            parsed: nil
end

defmodule Post.Manifest.Parsed do
  use TypedStruct

  typedstruct do
    field :title, String.t(), enforce: true
    field :description, String.t() | nil
    field :tags, [String.t(), ...], enforce: true
  end

  def new(title: title, tags: tags) do
    new(title: title, tags: tags, description: nil)
  end

  def new(title: title, tags: tags, description: description) do
    true = is_binary(title)
    true = is_nil(description) || is_binary(description)

    true =
      is_list(tags) &&
        Enum.count(tags) >= 1 &&
        Enum.all?(tags, fn tag -> is_binary(tag) end)

    %Post.Manifest.Parsed{
      title: title,
      tags: tags,
      description: description
    }
  end
end

defmodule Blog.Posts do
  use Agent

  @manifest_file "manifest.yaml"
  @content_file "post.html.heex"
  @path "lib/blog_web/templates/page/posts"

  def start_link([]) do
    IO.puts("post agent has started")
    Agent.start_link(fn -> load_posts() end, name: __MODULE__)
  end

  def parse_manifest(manifest) do
    manifest = YamlElixir.read_from_string!(manifest)
    title = Map.get(manifest, "title")
    description = Map.get(manifest, "description")
    tags = Map.get(manifest, "tags")

    Post.Manifest.Parsed.new(
      title: title,
      tags: tags,
      description: description
    )
  end

  def load_manifest(post_path) do
    path = Path.join(post_path, @manifest_file)

    case File.read(path) do
      {:ok, manifest} ->
        %Post.Manifest{
          path: path,
          content: manifest,
          parsed: parse_manifest(manifest)
        }

      {:error, :enoent} ->
        %Post.Manifest{
          path: path
          # error: :enoent
        }
    end
  end

  def load_posts do
    {:ok, posts} = File.ls(@path)

    IO.puts("Potential posts: " <> inspect(posts))

    posts
    |> Enum.map(fn fld_name ->
      path = Path.join(@path, fld_name)
      content_file_path = Path.join(path, @content_file)
      has_content = File.exists?(content_file_path)

      %Post{
        dt: Post.parse_datetime(fld_name),
        path: path,
        has_content: has_content,
        manifest: load_manifest(path)
      }
    end)
  end

  def ready_post?(%{manifest: nil}) do
    false
  end

  def ready_post?(%{manifest: %{parsed: nil}}) do
    false
  end

  def ready_post?(%{has_content: false}) do
    false
  end

  def ready_post?(%{manifest: %{parsed: _}, has_content: true}) do
    true
  end

  def value do
    if Mix.env() == :prod do
      Agent.get(__MODULE__, &Function.identity/1)
    else
      load_posts()
    end
  end

  # TODO find a way to reload state of this agent when
  # posts are updated to immediately see update in /posts/ in dev env.
  # it's hot-fixed in value()
  #   def reload do
  #     Agent.get(__MODULE__, fn _ -> load_posts() |> valid_posts() end)
  #   end

  def valid_posts(posts) do
    posts
    |> Enum.filter(fn post -> ready_post?(post) end)
  end
end
