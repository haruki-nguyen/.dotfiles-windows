# MCP for Unity — Setup Guide

## Installation Steps

### Prerequisites

* **Python 3.12+** → [Download](https://www.python.org/downloads/)
* **Unity 2021.3 LTS+** → [Download](https://unity.com/download)
* **uv (Python toolchain manager)**

  ```bash
  # macOS / Linux
  curl -LsSf https://astral.sh/uv/install.sh | sh

  # Windows
  winget install --id=astral-sh.uv -e
  ```

* **MCP Client:** Claude, Cursor, VSCode Copilot, Windsurf, etc.
* *(Optional)* Roslyn for advanced script validation.

### Step 1: Install the Unity Package From Git URL

1. Open Unity → **Window > Package Manager**
2. Click **+ → Add package from git URL…**
3. Paste:

   ```txt
   https://github.com/CoplayDev/unity-mcp.git?path=/MCPForUnity
   ```

4. Click **Add**.

> The MCP Server installs automatically on first run.
> If it fails, use Manual Configuration.

### Step 2: Configure Your MCP Client

#### Option A — Auto-Setup (Recommended)

1. In Unity: **Window > MCP for Unity → Auto-Setup**
2. Look for 🟢 “Connected ✓”.

#### Option B — Manual Configuration

If auto-setup fails:

* Locate your MCP client’s config file:

  * **macOS:** `~/Library/Application Support/Claude/claude_desktop_config.json`
  * **Windows:** `%APPDATA%\Claude\claude_desktop_config.json`
* Add or update the `mcpServers` section with the Unity MCP server paths.

## Usage

1. Open your Unity project.
2. Start your MCP Client (Claude, Cursor, etc.).
3. The MCP Server launches automatically and connects to Unity.
4. Interact naturally with prompts like:

   * “Create a 3D player controller.”
   * “Make a tic-tac-toe game in 3D.”
   * “Generate a cool shader and apply it to a cube.”
