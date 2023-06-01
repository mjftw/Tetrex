#!/bin/bash
# Docker entrypoint script.

mix deps.get

exec mix phx.server