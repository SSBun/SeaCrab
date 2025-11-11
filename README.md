# SeaCrab 🦀

A headless macOS AI application that refines selected text using OpenAI-compatible LLM services via a customizable global keyboard shortcut.

## Features

- **Headless Operation**: Runs silently in the menu bar with custom app icon
- **Multiple Refinement Cards**: Create multiple cards, each with its own prompt and keyboard shortcut
- **Visual Feedback**: Floating loading indicator follows your cursor while refining
- **OpenAI-Compatible**: Works with OpenAI, Anthropic, local LLMs, or any OpenAI-compatible API
- **Configurable Base URL**: Connect to any OpenAI-compatible endpoint
- **Test Connection**: Built-in connection testing to verify your API setup
- **Fully Customizable**: Configure API endpoint, model, and multiple refinement presets
- **Native macOS**: Built with SwiftUI for a seamless Mac experience

## How It Works

1. Create one or more refinement cards (each with a prompt and keyboard shortcut)
2. Select any text in any application
3. Press the shortcut for your desired refinement style
4. A loading indicator appears near your cursor showing progress
5. SeaCrab captures the text, sends it to your LLM with the card's prompt
6. The refined text automatically replaces your selection

## Setup

### 1. Build and Run

```bash
open SeaCrab.xcodeproj
# Build and run from Xcode (⌘R)
```

### 2. Grant Accessibility Permissions

When you first run SeaCrab, you'll be prompted to grant accessibility permissions:

1. Open **System Settings** → **Privacy & Security** → **Accessibility**
2. Enable **SeaCrab** in the list
3. Restart SeaCrab if needed

### 3. Configure API Settings and Refinement Cards

1. Click the SeaCrab icon (✨) in your menu bar
2. Select **Settings...**
3. Configure your API connection:
   - **Base URL**: OpenAI-compatible API endpoint
   - **API Key**: Your API key
   - **Model**: Model name to use
4. Click **Test Connection** to verify your setup
5. Create refinement cards:
   - Each card has a name, prompt, and keyboard shortcut
   - Default card: `Control + R` for general refinement
   - Click **+ Add New Refinement Card** to create more presets
   - Example: Create a "Grammar Only" card with `Control + Shift + R`

#### Provider Examples

**OpenAI**
- Base URL: `https://api.openai.com/v1`
- Model: `gpt-4o`, `gpt-4o-mini`, `gpt-3.5-turbo`
- Get your API key: [platform.openai.com](https://platform.openai.com/api-keys)

**Anthropic (via OpenAI-compatible endpoint)**
- Use a proxy like [OpenRouter](https://openrouter.ai/) or similar
- Base URL: `https://openrouter.ai/api/v1`
- Model: `anthropic/claude-3-5-sonnet`, `anthropic/claude-3-opus`
- Get your API key: [openrouter.ai](https://openrouter.ai/)

**Local LLM (LM Studio)**
- Base URL: `http://localhost:1234/v1`
- Model: Your local model name (e.g., `llama-3.2-3b`)
- API Key: Can be empty or any value

**Local LLM (Ollama with OpenAI compatibility)**
- Base URL: `http://localhost:11434/v1`
- Model: Your Ollama model name
- API Key: Can be empty or any value

## Usage

### Basic Usage

1. Set up one or more refinement cards with different prompts and shortcuts
2. Select text in any application (TextEdit, Safari, Slack, etc.)
3. Press the shortcut for your desired refinement (e.g., `Control + R` for general refinement)
4. A floating "Rewriting..." indicator appears and follows your cursor
5. Move your cursor freely - the indicator stays with you
6. Wait for the refinement to complete
7. Your text is automatically replaced with the refined version

### Settings

All settings are **saved automatically** as you type. A checkmark indicator confirms when changes are saved.

**Base URL**: OpenAI-compatible API endpoint
- Default: `https://api.openai.com/v1`
- Format: Full URL with `https://` prefix (e.g., `https://api.openai.com/v1`)
- The app automatically extracts the hostname and path for the SDK
- Works with any OpenAI-compatible service
- Auto-saved on change

**API Key**: Your API authentication key
- Stored securely in UserDefaults
- Auto-saved on change

**Model**: Model identifier
- Default: `gpt-4o`
- Can be any model supported by your endpoint
- Auto-saved on change

**Refinement Cards**: Multiple preset configurations
- Each card combines:
  - **Name**: Descriptive label (e.g., "Grammar Only", "Make Professional")
  - **Prompt**: Custom system prompt for refinement
  - **Keyboard Shortcut**: Unique global shortcut for this card
- Default card uses `Control + R` for general refinement
- Create multiple cards for different refinement styles:
  - `Control + R`: General refinement
  - `Control + Shift + R`: Grammar and spelling only
  - `Control + Option + R`: Make concise
  - `Control + Command + R`: Professional tone
- All changes auto-saved
- Minimum 1 card required (can't delete the last card)

## Technical Details

### Architecture

```
SeaCrab/
├── Models/
│   ├── AppSettings.swift          # Settings management with UserDefaults
│   └── RefinementCard.swift       # Card model (prompt + shortcut)
├── Services/
│   ├── LLMService.swift           # OpenAI-compatible API integration
│   ├── KeyboardShortcutMonitor.swift  # Multi-shortcut monitoring
│   └── TextRefinementService.swift    # Text capture & replacement
├── Views/
│   ├── SettingsView.swift         # Settings UI with connection testing
│   ├── RefinementCardView.swift   # Individual card editor
│   └── LoadingIndicatorWindow.swift  # Cursor-following progress UI
└── SeaCrabApp.swift               # App entry & menu bar
```

### Key Components

- **AppDelegate**: Manages menu bar icon, keyboard monitoring, and app lifecycle
- **RefinementCard**: Model combining prompt, shortcut, and name into a reusable preset
- **KeyboardShortcutMonitor**: Uses Carbon Event Taps to monitor multiple shortcuts simultaneously
- **TextRefinementService**: Handles text capture via pasteboard simulation and card-based refinement
- **LLMService**: Integration with OpenAI-compatible APIs via [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) package
- **LoadingIndicatorWindow**: Floating progress indicator that follows cursor at 60fps
- **RefinementCardView**: Interactive editor for creating and modifying refinement cards

### Requirements

- macOS 15.2+
- Xcode 16.2+
- Swift 6.0+
- Valid API key for your chosen OpenAI-compatible service

### Dependencies

- [MacPaw/OpenAI](https://github.com/MacPaw/OpenAI) - Swift package for OpenAI API interaction

### Permissions

- **Accessibility**: Required to monitor global keyboard shortcuts and simulate keyboard events for text capture/replacement

## Customization

### Creating Multiple Refinement Presets

Each refinement card allows a unique combination of prompt and keyboard shortcut:

1. Open Settings from the menu bar
2. Scroll to "Refinement Cards" section
3. Click **+ Add New Refinement Card**
4. Configure the card:
   - **Name**: Give it a descriptive name
   - **Keyboard Shortcut**: Click "Record" and press your desired combination
   - **Prompt**: Write or paste your custom refinement instructions
5. All changes auto-save
6. Create as many cards as you need for different refinement styles

**Example Setup:**
- Card 1: "Quick Fix" - `Control + R` - Grammar and spelling only
- Card 2: "Concise" - `Control + Shift + R` - Remove unnecessary words
- Card 3: "Professional" - `Control + Option + R` - Formal business tone
- Card 4: "Expand" - `Control + Command + R` - Add more details and context

### Using with Different Providers

SeaCrab works with any OpenAI-compatible API:

**Local LLM Servers:**
- [LM Studio](https://lmstudio.ai/) - `http://localhost:1234/v1`
- [Ollama](https://ollama.ai/) with OpenAI compatibility
- [text-generation-webui](https://github.com/oobabooga/text-generation-webui)

**Cloud Providers:**
- [OpenRouter](https://openrouter.ai/) - Access multiple models
- [Together AI](https://together.ai/)
- [Groq](https://groq.com/)
- Any other OpenAI-compatible endpoint

## Troubleshooting

### Shortcut Not Working

- Ensure accessibility permissions are granted
- Check if another app is using the same shortcut
- Try setting a different shortcut combination
- Restart SeaCrab after granting permissions

### API Errors

- Use the **Test Connection** button to verify your setup
- Verify your API key is correct
- Check the Base URL is properly formatted
- Ensure your API account has credits/access
- Check network connectivity

### Connection Testing

The "Test Connection" button sends a simple message to verify:
- Base URL is reachable
- API key is valid
- Model is accessible
- API returns valid responses

### Text Not Being Captured

- Some applications may block pasteboard access
- Try selecting text again before pressing the shortcut
- Check accessibility permissions are granted

## License

Created by caishilin on 2025/11/10.

## Contributing

This is a personal project, but feedback and suggestions are welcome!

