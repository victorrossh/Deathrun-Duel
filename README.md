# Deathrun Duel Plugin

## Description

The Deathrun Duel plugin is designed for Counter-Strike 1.6 servers to introduce a duel system, allowing players to engage in duels.

## Features

- Players can initiate a duel using the "/duel" command.
- Blocks certain actions during a duel, such as dropping weapons, picking up items, jumping, and accessing the shop.

## Commands

- `/duel`: Initiates the duel and opens a menu for weapon selection.
- `/shop`: Blocks access to the shop during a duel.

## Configuration

- The duel time can be configured using the cvar: `duel_time`. Default is 60.0 seconds.
