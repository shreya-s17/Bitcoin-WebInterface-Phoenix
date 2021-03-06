defmodule Bitcoin.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  def start(_type, _args) do
    #import Supervisor.Spec
    # List all child processes to be supervised
    #:ets.new(:table, [:bag, :named_table,:public])
    children = [
      # Start the Ecto repository
      #supervisor(SSUPERVISOR,[20]),
      Bitcoin.Repo,
      # Start the endpoint when the application starts
      BitcoinWeb.Endpoint
      # Starts a worker by calling: Bitcoin.Worker.start_link(arg)
      # {Bitcoin.Worker, arg},
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Bitcoin.Supervisor]
    Supervisor.start_link(children, opts)
  end


  # Tell Phoenix to update the endpoint configuration
  # whenever the application is updated.
  def config_change(changed, _new, removed) do
    BitcoinWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
