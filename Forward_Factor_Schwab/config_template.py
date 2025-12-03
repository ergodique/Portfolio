# Schwab API Configuration Template
# 
# INSTRUCTIONS:
# 1. Copy this file and rename it to "config.py"
# 2. Replace the placeholder values with your actual credentials
# 3. Get your credentials from https://developer.schwab.com
#
# SECURITY WARNING:
# - NEVER commit config.py to git (it's in .gitignore)
# - NEVER share your APP_KEY, APP_SECRET, or tokens.json

# Your Schwab Developer App Key (32 characters)
APP_KEY = "YOUR_32_CHARACTER_APP_KEY_HERE__"

# Your Schwab Developer App Secret (16 characters)
APP_SECRET = "YOUR_16_CHAR_KEY"

# Callback URL (must match what you registered in the developer portal)
CALLBACK_URL = "https://127.0.0.1"

# Path to store tokens (will be created automatically)
TOKENS_FILE = "tokens.json"

