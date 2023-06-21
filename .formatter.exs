[
  import_deps: [:phoenix],
  inputs: ["*.{ex,exs}", "{config,lib,test}/**/*.{ex,exs}"],
  plugins: [TailwindFormatter.MultiFormatter],
  inputs: [
    "*.{heex,ex,exs}",
    "priv/*/seeds.exs",
    "{config,lib,test}/**/*.{heex,ex,exs}"
  ]
]
