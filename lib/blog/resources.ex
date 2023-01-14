# used for link testing mentioned in blog posts (now only there)
# links are registered only during test mode and post rendering
# links are formed with: link, img, img_local, yt
#    (and with "code", but its validity is checked during rendering, so skip this type)
#
# TODO refactor the whole resource testing part
# it's jolly useful and not pretty
defmodule Blog.Test.Links do
  use Agent

  def start_link([]) do
    IO.puts("link repository for testing has started")
    Agent.start_link(&load_state/0, name: __MODULE__)
  end

  defp load_state do
    state = %{
      urls: MapSet.new()
    }

    state
  end

  defp set(value) do
    Agent.update(__MODULE__, fn _ -> value end)
  end

  def value do
    Agent.get(__MODULE__, &Function.identity/1)
  end

  def urls do
    Map.get(value(), :urls)
  end

  def local_urls do
    Enum.filter(urls(), &is_local?/1)
  end

  def add(url) do
    if !MapSet.member?(urls(), url) do
      # IO.puts("added link... " <> url)
    end

    Agent.update(__MODULE__, fn %{:urls => urls} -> %{urls: MapSet.put(urls, url)} end)
  end

  def clear do
    set(load_state())
  end

  def is_local?(url) do
    String.starts_with?(url, "/")
  end
end
