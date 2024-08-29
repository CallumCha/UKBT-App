# UKBT App for Tournaments

## Overview

A beach volleyball app to register players for tournaments, manage tournament processes, and track player rankings using an ELO system.

### Key Features

- Player registration for tournaments with partners
- Automatic seeding and knockout match creation based on pool results
- ELO ranking system for players
- Streamlined tournament management

## Motivation

This app aims to modernize and accelerate the current tournament registration and management process in beach volleyball. By automating seeding and match creation, we can significantly improve the efficiency of tournament operations.

## ELO Ranking System

- ELO is a rating assigned to each player
- ELO updates after every match, with changes visible at the end of a tournament
- Player profiles display ELO history (last 90/150/365 days)

### To Be Decided
- Should ELO changes be displayed for each match? Only for matches the player participated in?
- Should the ELO of all tournament participants be visible?

For more information on the ELO system implementation, see [this article](https://towardsdatascience.com/developing-an-elo-based-data-driven-ranking-system-for-2v2-multiplayer-games-7689f7d42a53).

## Planned Features

### Tournament Matches
- Implement a 'Your Matches' feature
- Display user's matches on the home page
- Improve layout for tournament tabs

### Rankings
- Display everyone's ELO on the UKBT
- Show user's position with quick navigation to their ranking

### Home Screen
- Display upcoming tournaments (within the month)
- Show upcoming matches (within the day)

### Matches
- Include referee team information
- Use actual scores instead of just win/loss

## Figma Designs

<img src="https://github.com/user-attachments/assets/c8d568a2-376d-4f9c-aae8-c1ae7e8a7a58" width="200" alt="Design 1">
<img src="https://github.com/user-attachments/assets/d99cf065-dc15-4c3f-b726-586149c07cbd" width="200" alt="Design 2">
<img src="https://github.com/user-attachments/assets/7814adfc-7d3d-4196-8138-187490cd04f1" width="200" alt="Design 3">
<img src="https://github.com/user-attachments/assets/b77afa69-3eac-453a-808f-f189037f7bbf" width="200" alt="Design 4">
