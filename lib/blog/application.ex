defmodule Blog.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      # Start the Ecto repository
      Blog.Repo,

      # Start the Telemetry supervisor
      BlogWeb.Telemetry,
      # Start the PubSub system
      {Phoenix.PubSub, name: Blog.PubSub},
      # Start posts collection
      Blog.Posts,
      # Start the Endpoint (http/https)
      BlogWeb.Endpoint
      # Start a worker by calling: Blog.Worker.start_link(arg)
      # {Blog.Worker, arg}
    ]

    children =
      case Mix.env() do
        :test ->
          children ++
            [
              # Init resource list for testing
              Blog.Test.Links
            ]

        _ ->
          children
      end

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Blog.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  @impl true
  def config_change(changed, _new, removed) do
    BlogWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
