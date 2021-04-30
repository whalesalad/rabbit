defmodule Rabbit.MixProject do
  use Mix.Project

  @app :rabbit
  @version "0.1.0"
  @all_targets [
    :rpi4,
    :rpi4_rabbit,
    :x86_64
  ]

  def project do
    [
      app: @app,
      version: @version,
      elixir: "~> 1.9",
      archives: [nerves_bootstrap: "~> 1.6"],
      start_permanent: Mix.env() == :prod,
      build_embedded: true,
      aliases: [loadconfig: [&bootstrap/1]],
      deps: deps(),
      releases: [{@app, release()}],
      preferred_cli_target: [run: :host, test: :host]
    ]
  end

  # Starting nerves_bootstrap adds the required aliases to Mix.Project.config()
  # Aliases are only added if MIX_TARGET is set.
  def bootstrap(args) do
    Application.start(:nerves_bootstrap)
    Mix.Task.run("loadconfig", args)
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Rabbit.Application, []},
      extra_applications: [:logger, :runtime_tools, :inets]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      # Dependencies for all targets
      {:nerves, "~> 1.7.5", runtime: false},
      {:shoehorn, "~> 0.7"},
      {:ring_logger, "~> 0.8"},
      {:toolshed, "~> 0.2"},

      #
      # {:circuits_gpio, "~> 0.4.3"},
      {:circuits_i2c, "~> 0.3.7"},
      # {:circuits_spi, "~> 0.1.4"},
      {:circuits_uart, "~> 1.4.2"},

      # Dependencies for all targets except :host
      {:nerves_runtime, "~> 0.10", targets: @all_targets},
      {:busybox, "~> 0.1", targets: @all_targets},
      {:vintage_net, "~> 0.7.0", targets: @all_targets},
      {:vintage_net_wifi, "~> 0.7.0", targets: @all_targets},
      # {:vintage_net_ethernet, "~> 0.7.0", targets: @all_targets},
      # {:vintage_net_direct, "~> 0.7.0", targets: @all_targets},
      {:nerves_time, "~> 0.2", targets: @all_targets},
      {:mdns_lite, "~> 0.4", targets: @all_targets},
      {:nerves_ssh, "~> 0.1.0", targets: @all_targets},

      {:binary, "~> 0.0.5"},
      {:httpoison, "~> 1.7"},
      {:poison, "~> 3.1"},

      # display
      {:oled, "~> 0.3.4"},
      {:chisel, "~> 0.2.0"},

      #

      # {:nerves_init_gadget, "~> 0.4", targets: @all_targets},

      # Dependencies for specific targets
      # {:nerves_system_rpi, "~> 1.8", runtime: false, targets: :rpi},
      # {:nerves_system_rpi0, "~> 1.8", runtime: false, targets: :rpi0},
      # {:nerves_system_rpi2, "~> 1.8", runtime: false, targets: :rpi2},
      # {:nerves_system_rpi3, "~> 1.8", runtime: false, targets: :rpi3},
      # {:nerves_system_rpi3a, "~> 1.8", runtime: false, targets: :rpi3a},
      # {:nerves_system_bbb, "~> 2.3", runtime: false, targets: :bbb},

      # {:nerves_system_rpi4, "~> 1.8", runtime: false, targets: :rpi4},
      # {:nerves_system_x86_64, "~> 1.13.3", runtime: false, targets: :x86_64},

      {:rpi4_rabbit, path: "/Users/michael/Code/rpi4_rabbit", runtime: false, targets: :rpi4_rabbit},
    ]
  end

  def release do
    [
      overwrite: true,
      cookie: "rabbit",
      include_erts: &Nerves.Release.erts/0,
      steps: [&Nerves.Release.init/1, :assemble],
      strip_beams: Mix.env() == :prod
    ]
  end
end
