defmodule Post do
  defstruct [
    :id,
    :path_from_root,
    :path_for_render,
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
    invalid_field = fn field_name ->
      {:error, field_name}
    end

    cond do
      !is_binary(title) ->
        invalid_field.(:title)

      !(is_nil(description) || is_binary(description)) ->
        invalid_field.(:description)

      !(is_list(tags) &&
          Enum.count(tags) >= 1 &&
            Enum.all?(tags, fn tag -> is_binary(tag) end)) ->
        invalid_field.(:tags)

      true ->
        {:ok,
         %Post.Manifest.Parsed{
           title: title,
           tags: tags,
           description: description
         }}
    end
  end
end

defmodule Blog.Posts do
  use Agent

  @manifest_file "manifest.yaml"
  @content_html "post.html"
  @content_file @content_html <> ".heex"
  @posts_path_for_render "posts/"
  @posts_path_from_root Path.join("lib/blog_web/templates/page/", @posts_path_for_render)

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
          parsed:
            case parse_manifest(manifest) do
              {:ok, manifest} ->
                manifest

              {:error, field} ->
                raise "manifest has invalid field '#{field}'. path: #{path}"
            end
        }

      {:error, :enoent} ->
        %Post.Manifest{
          path: path
          # error: :enoent
        }
    end
  end

  def load_posts do
    {:ok, posts} = File.ls(@posts_path_from_root)

    IO.puts("Potential posts: " <> inspect(posts))

    posts
    |> Enum.map(fn fld_name ->
      path_from_root = Path.join(@posts_path_from_root, fld_name)
      path_for_render = Path.join([@posts_path_for_render, fld_name, @content_html])
      content_file_path = Path.join(path_from_root, @content_file)
      has_content = File.exists?(content_file_path)

      %Post{
        id: fld_name,
        dt: Post.parse_datetime(fld_name),
        path_from_root: path_from_root,
        path_for_render: path_for_render,
        has_content: has_content,
        manifest: load_manifest(path_from_root)
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

  # TODO optimize using mapping on necessity
  def post_by_id(id) do
    value()
    |> valid_posts()
    |> Enum.find(nil, fn post -> post.id == id end)
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

  def invalid_posts(posts) do
    posts
    |> Enum.filter(fn post -> !ready_post?(post) end)
  end

  def page_exists?(page) do
    valid_posts = Blog.Posts.value() |> Blog.Posts.valid_posts()
    posts_per_page = 1
    Enum.count(valid_posts) >= page * posts_per_page
  end
end
