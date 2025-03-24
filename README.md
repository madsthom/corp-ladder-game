# Corporate Ladder

A vertical platforming game where you climb the tech stack! Jump your way up through platforms while collecting programming language power-ups.

## How to Play

- **Left/Right Arrow Keys** or **A/D**: Move left/right
- **Space** or **Click**: Start game/Restart after game over
- **Screen Wrap**: Walk through one side of the screen to appear on the other side

## Power-ups

- **TypeScript (Blue)**: Jump Boost - Higher jumps for 5 seconds
- **Keyboard (Green)**: Score Boost - Double points for 5 seconds
- **Haskell (Purple)**: Swoosh - Temporary upward boost
- **Rust (Gold)**: Wide Platforms - Wider platforms for 5 seconds

## Building the Game

### Requirements

- LÖVE 11.4 or higher (<https://love2d.org/>)

### Install Lua and Dependencies

```bash
./install-lua.sh
```

### Running the Game

1. Download the release package
2. Double-click the .love file
   - Or run `love .` in the game directory

### Creating a Release Build

```bash
# Windows (64-bit)
love-release -W 64

# macOS
love-release -M

# Linux
love-release -L
```

## Credits

Made with LÖVE framework (<https://love2d.org/>)
