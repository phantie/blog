defmodule Post.Manifest do
  defstruct path: nil,
            content: nil,
            parsed: nil

  @manifest_file "manifest.yaml"

  defp parse(manifest) do
    manifest = YamlElixir.read_from_string!(manifest)

    Post.Manifest.Parsed.new(
      id: manifest["id"],
      title: manifest["title"],
      tags: manifest["tags"],
      description: manifest["description"]
    )
  end

  def load(post_path) do
    path = Path.join(post_path, @manifest_file)

    case File.read(path) do
      {:ok, manifest} ->
        %Post.Manifest{
          path: path,
          content: manifest,
          parsed:
            case parse(manifest) do
              {:ok, manifest} ->
                manifest

              {:error, field} ->
                raise "manifest has invalid field '#{field}'. path: #{path}"
            end
        }

      {:error, :enoent} ->
        %Post.Manifest{
          path: path
        }
    end
  end
end

defmodule Post.Manifest.Parsed do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
    field :title, String.t(), enforce: true
    field :description, String.t() | nil
    field :tags, [String.t(), ...], enforce: true
  end

  def new(id: id, title: title, tags: tags) do
    new(id: id, title: title, tags: tags, description: nil)
  end

  def new(id: id, title: title, tags: tags, description: description) do
    invalid_field = fn field_name ->
      {:error, field_name}
    end

    not_contains_space = fn str ->
      is_binary(str) && !String.contains?(str, " ")
    end

    cond do
      !(is_binary(id) && not_contains_space.(id)) ->
        invalid_field.(:id)

      !is_binary(title) ->
        invalid_field.(:title)

      !(is_nil(description) || is_binary(description)) ->
        invalid_field.(:description)

      # no idea how to pass an anon fn here simpler
      # like &not_contains_space/1
      !(is_list(tags) &&
          Enum.count(tags) >= 1 &&
            Enum.all?(tags, &not_contains_space.(&1))) ->
        invalid_field.(:tags)

      true ->
        {:ok,
         %Post.Manifest.Parsed{
           id: id,
           title: title,
           tags: tags,
           description: description
         }}
    end
  end
end
