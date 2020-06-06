defmodule EventDashboard.MixProject do
  use Mix.Project

  @version "0.1.0"

  def project do
    [
      app: :event_dashboard,
      version: @version,
      elixir: "~> 1.7",
      compilers: [:phoenix] ++ Mix.compilers(),
      elixirc_paths: elixirc_paths(Mix.env()),
      deps: deps(),
      name: "EventDashboard",
      description: "Real-time performance event dashboard",
      aliases: aliases(),
      xref: [exclude: [:cpu_sup, :disksup, :memsup]]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {EventDashboard.Application, []},
      extra_applications: [:logger, :logger_file_backend, :redi]
    ]
  end

  defp aliases do
    [
      setup: ["deps.get", "cmd npm install --prefix assets"],
      dev: "run --no-halt dev.exs"
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:logger_file_backend, "~> 0.0.11"},
      {:phoenix_live_view, "~> 0.13.3"},
      {:telemetry_metrics, "~> 0.4.0 or ~> 0.5.0"},
      {:phoenix_html, "~> 2.14.1 or ~> 2.15"},
      {:telemetry_poller, "~> 0.4", only: :dev},
      {:phoenix_live_reload, "~> 1.2", only: :dev},
      {:plug_cowboy, "~> 2.0", only: :dev},
      {:jason, "~> 1.0", only: [:dev, :test, :docs]},
      {:floki, "~> 0.24.0", only: :test},
      {:redi, git: "git://github.com/bougueil/erlang-redi", app: false},
      {:ex_doc, "~> 0.21", only: :docs}
    ]
  end

end
