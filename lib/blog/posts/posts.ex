defmodule Blog.Posts do
  use Agent

  def start_link([]) do
    IO.puts("post agent has started")
    Agent.start_link(&load_state/0, name: __MODULE__)
  end

  defp tag_to_posts(valid_posts) do
    valid_posts
    |> Enum.flat_map(fn post ->
      post.manifest.parsed.tags
      |> Enum.map(fn tag -> {tag, post} end)
    end)
    |> Enum.group_by(fn {tag, _post} -> tag end)
    |> Map.to_list()
    |> Enum.map(fn {tag, tag_to_post_list} ->
      {tag, Enum.map(tag_to_post_list, fn {_tag, post} -> post end)}
    end)
    |> Enum.into(%{})
  end

  defp load_state do
    all_posts = Post.load_all() |> sort_by_desc_time()
    valid_posts = all_posts |> valid_posts()
    invalid_posts = all_posts |> invalid_posts()
    tag_to_valid_posts = tag_to_posts(valid_posts)

    tag_to_valid_posts_for_display =
      tag_to_valid_posts
      |> Map.to_list()
      |> Enum.map(fn {tag, posts} -> {tag, posts_for_display(posts)} end)
      |> Enum.into(%{})

    %{
      all: all_posts,
      valid: valid_posts,
      invalid: invalid_posts,
      id_to_valid:
        valid_posts |> Enum.map(fn p -> {p.manifest.parsed.id, p} end) |> Enum.into(%{}),
      valid_count: Enum.count(valid_posts),
      invalid_count: Enum.count(invalid_posts),
      for_display: posts_for_display(valid_posts),
      map_from_tag: tag_to_valid_posts,
      map_from_tag_for_display: tag_to_valid_posts_for_display
    }
  end

  defp value(key)
       when key in [
              :all,
              :valid,
              :invalid,
              :id_to_valid,
              :valid_count,
              :invalid_count,
              :for_display,
              :map_from_tag,
              :map_from_tag_for_display
            ] do
    value()[key]
  end

  defp value do
    if Mix.env() == :prod do
      Agent.get(__MODULE__, &Function.identity/1)
    else
      load_state()
    end
  end

  def valid_posts, do: value(:valid)
  def invalid_posts, do: value(:invalid)
  def valid_post_count, do: value(:valid_count)
  def invalid_post_count, do: value(:invalid_count)
  def id_to_valid_post, do: value(:id_to_valid)
  def posts_for_display, do: value(:for_display)
  def tag_to_valid_posts, do: value(:map_from_tag)
  def tag_to_valid_posts_for_display, do: value(:map_from_tag_for_display)

  def valid_post_by_id(id), do: id_to_valid_post()[id]

  # TODO find a way to reload state of this agent when
  # posts are updated to immediately see update in /posts/ in dev env.
  # it's hot-fixed in value() with performance drawback in development
  #   def reload do
  #     Agent.get(__MODULE__, fn _ -> load_posts() |> valid_posts() end)
  #   end

  def post_page_exists?(posts, page, posts_per_page: posts_per_page) do
    Enum.count(posts) >= page * posts_per_page
  end

  def take_page(posts, page, posts_per_page) do
    posts
    |> Stream.chunk_every(posts_per_page)
    |> Enum.at(page - 1) || []
  end

  defp valid_posts(posts) do
    posts
    |> Enum.filter(fn post -> Post.ready?(post) end)
  end
  defp invalid_posts(posts) do
    posts
    |> Enum.filter(fn post -> !Post.ready?(post) end)
  end

  defp sort_by_desc_time(posts) do
    posts
    |> Enum.sort_by(fn post -> post.dt end, {:desc, NaiveDateTime})
  end

  defp posts_for_display(valid_posts) do
    valid_posts
    |> Enum.map(fn post ->
      post.manifest.parsed
      |> Map.take([:title, :description, :tags])
      |> Map.put(
        :date,
        case Timex.format(post.dt, "{Mfull} {D}, {YYYY}") do
          {:ok, fmt} -> fmt
        end
      )
      |> Map.put(:id, post.manifest.parsed.id)
    end)
  end
end
