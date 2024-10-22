# Tetrex

Yet another Tetris game, because everyone loves Tetris!

I did a talk on the game at CodeBeam Europe, you can watch it here:

[![Building Multiplayer Tetris from scratch with OTP, Elixir, and Phoenix by Merlin Webster | Code BEAM
](https://img.youtube.com/vi/87iFws4c78s/0.jpg)](https://www.youtube.com/watch?v=87iFws4c78s)

https://www.youtube.com/watch?v=87iFws4c78s&pp=ygUQdGV0cmV4IGNvZGUgYmVhbQ%3D%3D

## How to play

The easiest way to play is to head on over to https://tetrex.fly.dev/

If you'd like to run it locally, you can do so with:

```sh
mix phx.server
```

Or run it using Docker with:

```sh
docker compose up -f docker_dev/docker-compose.yml
```

Head on over to http://localhost:4000 and you're in!

## Features

Features:

- It's Tetris, so all the basic Tetris stuff
- Your game is saved automatically, so you can safely close your browser tab and come back

Upcoming:

- Multiplayer battles!

## Documentation

You can find a huge diagram explaining how everything works in great detail on [this Miro board](https://miro.com/app/board/uXjVMCAiwn8=/?share_link_id=465426947222).

## Developer things

The version is bumped using the excellent [Versiose](https://hexdocs.pm/versioce/readme.html) package.

You can do this with:

```sh
mix bump patch
#OR
mix bump minor
#OR
mix bump major
```

This will only succeed if you have no uncommitted git changes.
It will create an update commit for you, tagging the new version.

To deploy: `fly deploy`
