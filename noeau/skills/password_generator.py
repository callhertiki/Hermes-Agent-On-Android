"""
password_generator.py — Noeau Guardian: Password & Passphrase Generator

Uses Python's built-in `secrets` module, which is designed for
cryptographic security. This is safer than `random`, which is not
suitable for passwords.

SAFETY RULES:
- Passwords are DISPLAYED in the terminal only.
- Nothing is saved to disk automatically.
- You choose whether to copy or store them.
- Real passwords must go into KeePassXC — never plain text files.
"""

import os
import secrets
import string


# ── WORD LIST ───────────────────────────────────────────────────────────────
# These 120 words are used for passphrase generation.
# A passphrase is 4+ random words joined together: "forest-copper-river-titan"
# It's easier to remember than "xK9#mP2@" but just as secure.
#
# For maximum security, replace this with the full EFF Large Word List:
# https://www.eff.org/files/2016/07/18/eff_large_wordlist.txt
# (7776 words — download and load it with open() for stronger passphrases)

WORD_LIST = [
    "amber", "anchor", "apple", "arctic", "arrow", "atlas", "autumn",
    "badger", "basket", "beacon", "birch", "blaze", "bolt", "boulder",
    "bridge", "bronze", "brook", "candle", "canyon", "carbon", "castle",
    "cedar", "cipher", "citrus", "cobalt", "compass", "copper", "coral",
    "crown", "crystal", "dagger", "delta", "desert", "dusk", "echo",
    "ember", "engine", "falcon", "feather", "flame", "forest", "forge",
    "frost", "garnet", "ghost", "glacier", "glass", "golden", "granite",
    "gravel", "grove", "hammer", "harbor", "haven", "hollow", "honor",
    "hunter", "igloo", "indigo", "input", "iron", "island", "ivory",
    "jade", "jasper", "judge", "jungle", "kettle", "king", "kindle",
    "knight", "lantern", "lava", "legend", "limit", "lotus", "lunar",
    "magic", "marble", "mission", "mossy", "mountain", "nerve", "night",
    "noble", "north", "oak", "ocean", "onyx", "orbit", "palace",
    "peak", "pepper", "pine", "planet", "power", "prism", "pulse",
    "quartz", "quick", "radar", "rebel", "ridge", "river", "royal",
    "ruby", "sage", "sapphire", "scout", "shadow", "shield", "silver",
    "slate", "smoke", "solar", "spark", "steel", "stone", "storm",
    "swift", "thunder", "timber", "titan", "torch", "topaz", "tundra",
    "unity", "ultra", "unlock", "valley", "vapor", "violet", "viper",
    "walnut", "water", "wave", "winter", "wolf", "xenon", "yield", "zenith"
]


def generate_password(
    length: int = 20,
    use_uppercase: bool = True,
    use_digits: bool = True,
    use_symbols: bool = True
) -> str:
    """
    Generate a strong random password using the `secrets` module.

    Parameters:
        length        — How many characters long (default: 20)
        use_uppercase — Include capital letters A-Z (default: yes)
        use_digits    — Include numbers 0-9 (default: yes)
        use_symbols   — Include symbols like !@#$% (default: yes)

    Returns:
        A randomly generated password string.

    Example output: "mK9#pL2@xR7!nQ4$vT8"
    """

    # Start with lowercase letters — these are always included
    character_pool = string.ascii_lowercase  # a-z

    # Add more character types based on what the user wants
    if use_uppercase:
        character_pool += string.ascii_uppercase  # A-Z

    if use_digits:
        character_pool += string.digits  # 0-9

    if use_symbols:
        # These symbols are widely accepted by websites
        character_pool += "!@#$%^&*()_+-=[]{}|;:,.<>?"

    # Safety check: we need at least some characters to choose from
    if not character_pool:
        character_pool = string.ascii_lowercase

    # Build the password one character at a time using secrets.choice()
    # secrets.choice() picks one item from a list using a cryptographically
    # secure random number — much safer than random.choice()
    password = "".join(secrets.choice(character_pool) for _ in range(length))

    return password


def generate_passphrase(
    word_count: int = 4,
    separator: str = "-"
) -> str:
    """
    Generate a passphrase: multiple random words joined together.

    A passphrase is easier to remember than a random password
    but can be just as secure if you use enough words.

    Example: "forest-copper-river-titan"
    With 4 words from 120, there are 120^4 = ~207 million combinations.
    With 5 words: ~24 billion combinations.

    Parameters:
        word_count — How many words to use (default: 4, recommend 4-6)
        separator  — What to put between words (default: -)

    Returns:
        A passphrase string.
    """

    # Pick 'word_count' random words from our word list
    # secrets.choice() picks one word at a time
    words = [secrets.choice(WORD_LIST) for _ in range(word_count)]

    # Join the words with the separator
    passphrase = separator.join(words)

    return passphrase


def estimate_strength(password: str) -> str:
    """
    Give a rough estimate of password strength.

    This is a simple check — not a full cryptographic analysis.
    It looks at length and character variety.

    Returns: "Weak", "Fair", "Strong", or "Very Strong"
    """

    score = 0

    # Length scoring
    if len(password) >= 8:
        score += 1
    if len(password) >= 12:
        score += 1
    if len(password) >= 16:
        score += 1
    if len(password) >= 20:
        score += 1

    # Character variety scoring
    if any(c.islower() for c in password):
        score += 1  # Has lowercase
    if any(c.isupper() for c in password):
        score += 1  # Has uppercase
    if any(c.isdigit() for c in password):
        score += 1  # Has numbers
    if any(not c.isalnum() for c in password):
        score += 1  # Has symbols

    # Map score to label
    if score <= 3:
        return "Weak"
    elif score <= 5:
        return "Fair"
    elif score <= 7:
        return "Strong"
    else:
        return "Very Strong"


def _clear_screen():
    """
    Clear the terminal screen to remove the generated password from view.
    Uses 'cls' on Windows and 'clear' on Linux/Mac.
    This is a security measure — not just cosmetic.
    """
    os.system("cls" if os.name == "nt" else "clear")


def run_interactive():
    """
    Interactive menu for password and passphrase generation.
    Called from main.py when the user selects Password Generator.
    """

    print("\n" + "=" * 50)
    print("  Noeau Password Generator")
    print("  Powered by Python `secrets` module")
    print("=" * 50)
    print()
    print("  [1] Generate a random password")
    print("  [2] Generate a passphrase (easier to remember)")
    print("  [3] Generate both")
    print("  [B] Back to main menu")
    print()

    choice = input("  Choose: ").strip().upper()

    if choice == "1":
        _interactive_password()

    elif choice == "2":
        _interactive_passphrase()

    elif choice == "3":
        _interactive_password()
        print()
        _interactive_passphrase()

    elif choice == "B":
        return

    else:
        print("[!] Invalid choice.")


def _interactive_password():
    """Ask for password preferences and display the result."""

    print()
    print("  Password settings (press Enter to use defaults):")

    # Ask for length
    length_input = input("  Length [default: 20]: ").strip()
    length = int(length_input) if length_input.isdigit() else 20

    # Ask about character types
    symbols_input = input("  Include symbols like !@#$%? [Y/n]: ").strip().upper()
    use_symbols = symbols_input != "N"

    digits_input = input("  Include numbers? [Y/n]: ").strip().upper()
    use_digits = digits_input != "N"

    upper_input = input("  Include uppercase letters? [Y/n]: ").strip().upper()
    use_upper = upper_input != "N"

    # Generate the password
    password = generate_password(
        length=length,
        use_uppercase=use_upper,
        use_digits=use_digits,
        use_symbols=use_symbols
    )

    strength = estimate_strength(password)

    print()
    print("  " + "─" * 46)
    print(f"  Generated password:")
    print()
    print(f"  {password}")
    print()
    print(f"  Strength: {strength}")
    print(f"  Length:   {len(password)} characters")
    print("  " + "─" * 46)
    print()
    print("  [!] Copy this password now. It will NOT be saved.")
    print("  [!] Store it in KeePassXC — never in a plain text file.")
    print()

    # Give them a moment to copy it before the screen moves on
    input("  Press Enter when you have copied the password... ")
    _clear_screen()
    print("  [*] Password cleared from screen. Good practice.")
    print("  [!] Reminder: Store it in KeePassXC only.")


def _interactive_passphrase():
    """Ask for passphrase preferences and display the result."""

    print()
    print("  Passphrase settings (press Enter to use defaults):")

    word_count_input = input("  Number of words [default: 4]: ").strip()
    word_count = int(word_count_input) if word_count_input.isdigit() else 4

    separator_input = input("  Separator between words [default: -]: ").strip()
    separator = separator_input if separator_input else "-"

    # Generate the passphrase
    passphrase = generate_passphrase(word_count=word_count, separator=separator)

    print()
    print("  " + "─" * 46)
    print(f"  Generated passphrase:")
    print()
    print(f"  {passphrase}")
    print()
    print(f"  Words: {word_count}  |  Strength: {estimate_strength(passphrase)}")
    print("  " + "─" * 46)
    print()
    print("  [!] Copy this passphrase now. It will NOT be saved.")
    print("  [!] Store it in KeePassXC — never in a plain text file.")
    print()

    input("  Press Enter when you have copied the passphrase... ")
    _clear_screen()
    print("  [*] Passphrase cleared from screen. Good practice.")
    print("  [!] Reminder: Store it in KeePassXC only.")
