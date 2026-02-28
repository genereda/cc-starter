#!/usr/bin/env python3
"""
Skill validation script - checks SKILL.md files for common issues.

Usage:
    python scripts/validate_skill.py [path/to/SKILL.md]
    python scripts/validate_skill.py [path/to/skill-directory]

If no path provided, validates SKILL.md in current directory.
"""

import re
import sys
from pathlib import Path


class ValidationResult:
    def __init__(self):
        self.errors = []
        self.warnings = []

    def error(self, msg: str):
        self.errors.append(f"ERROR: {msg}")

    def warn(self, msg: str):
        self.warnings.append(f"WARNING: {msg}")

    def is_valid(self) -> bool:
        return len(self.errors) == 0

    def print_report(self):
        if self.errors:
            for e in self.errors:
                print(f"  ✗ {e}")
        if self.warnings:
            for w in self.warnings:
                print(f"  ⚠ {w}")
        if self.is_valid() and not self.warnings:
            print("  ✓ All checks passed")


def parse_frontmatter(content: str) -> tuple[dict, str]:
    """Parse YAML frontmatter and return (metadata, body)."""
    if not content.startswith("---"):
        return {}, content

    parts = content.split("---", 2)
    if len(parts) < 3:
        return {}, content

    frontmatter_text = parts[1].strip()
    body = parts[2].strip()

    # Simple YAML parsing for name and description
    metadata = {}
    current_key = None
    current_value = []

    for line in frontmatter_text.split("\n"):
        # Check for new key
        key_match = re.match(r'^(\w+):\s*(.*)', line)
        if key_match:
            # Save previous key if exists
            if current_key:
                metadata[current_key] = " ".join(current_value).strip()

            current_key = key_match.group(1)
            value = key_match.group(2).strip()

            # Handle multi-line indicator
            if value == ">-" or value == "|":
                current_value = []
            else:
                current_value = [value]
        elif current_key and line.startswith("  "):
            # Continuation of multi-line value
            current_value.append(line.strip())

    # Save last key
    if current_key:
        metadata[current_key] = " ".join(current_value).strip()

    return metadata, body


def validate_name(name: str, result: ValidationResult):
    """Validate skill name format."""
    if not name:
        result.error("Missing 'name' in frontmatter")
        return

    if len(name) > 64:
        result.error(f"Name exceeds 64 characters ({len(name)} chars): '{name}'")

    if name != name.lower():
        result.error(f"Name must be lowercase: '{name}'")

    if not re.match(r'^[a-z][a-z0-9-]*$', name):
        result.error(f"Name must start with letter, contain only lowercase letters, numbers, hyphens: '{name}'")

    if name.startswith("-") or name.endswith("-"):
        result.error(f"Name cannot start or end with hyphen: '{name}'")

    if "--" in name:
        result.error(f"Name cannot contain consecutive hyphens: '{name}'")

    # Check for reserved/vague terms
    reserved = ["helper", "utils", "tools", "misc", "stuff", "thing"]
    for term in reserved:
        if name == term or name.endswith(f"-{term}"):
            result.warn(f"Name contains vague term '{term}' - consider more specific naming")


def validate_description(description: str, result: ValidationResult):
    """Validate description content and length."""
    if not description:
        result.error("Missing 'description' in frontmatter")
        return

    if len(description) > 1024:
        result.error(f"Description exceeds 1024 characters ({len(description)} chars)")

    if len(description) < 20:
        result.warn(f"Description is very short ({len(description)} chars) - may not trigger reliably")

    # Check for first-person language
    first_person = re.search(r'\b(I can|I will|I help|I\'m|I am)\b', description, re.IGNORECASE)
    if first_person:
        result.warn(f"Description uses first-person ('{first_person.group()}') - use third-person instead")

    # Check for vague patterns
    vague_patterns = [
        (r'^helps? with\b', "Starts with vague 'helps with'"),
        (r'^does? stuff\b', "Uses vague 'does stuff'"),
        (r'^handles?\b', "Starts with vague 'handles'"),
        (r'^works? with\b', "Starts with vague 'works with'"),
    ]
    for pattern, msg in vague_patterns:
        if re.search(pattern, description, re.IGNORECASE):
            result.warn(f"{msg} - be more specific about actions")

    # Check for "Use when" trigger phrase
    if "use when" not in description.lower():
        result.warn("Description lacks 'Use when' trigger phrases - may not trigger reliably")

    # Check for XML tags (not allowed)
    if re.search(r'<[^>]+>', description):
        result.error("Description contains XML tags - these are not allowed")


def validate_body(body: str, result: ValidationResult):
    """Validate SKILL.md body content."""
    lines = body.split("\n")
    line_count = len(lines)

    if line_count >= 500:
        result.warn(f"Body has {line_count} lines (target <500) - consider using references/")

    # Check for Windows paths - but skip lines that are clearly examples/anti-patterns
    for i, line in enumerate(lines, 1):
        # Skip lines in code blocks showing examples, table cells with backticks, or "Bad" examples
        if '`' in line and ('\\' in line.split('`')[1] if line.count('`') >= 2 else False):
            continue  # Skip inline code examples
        if line.strip().startswith("**Bad"):
            continue
        if "| Windows paths" in line:
            continue

        # Look for actual Windows path usage (not in backticks)
        # Match: C:\, D:\, scripts\file, references\file, assets\file
        windows_match = re.search(r'(?<!`)[a-zA-Z]:\\|(?<!`)(?:scripts|references|assets)\\[a-zA-Z]', line)
        if windows_match:
            result.error(f"Windows-style path on line {i}: '{windows_match.group()}' - use forward slashes")

    # Check for deeply nested references
    nested_refs = re.findall(r'\[.*?\]\((references/[^)]+/[^)]+)\)', body)
    if nested_refs:
        result.warn(f"Deeply nested reference paths detected: {nested_refs[:3]} - keep references one level deep")

    # Check for inconsistent reference paths
    refs = re.findall(r'\[.*?\]\((\.\./[^)]+|/[^)]+)\)', body)
    for ref in refs[:3]:
        if ref.startswith(".."):
            result.warn(f"Parent directory reference '{ref}' - may break portability")
        elif ref.startswith("/"):
            result.warn(f"Absolute path reference '{ref}' - use relative paths")


def validate_structure(skill_dir: Path, result: ValidationResult):
    """Validate skill directory structure."""
    # Check for discouraged files
    discouraged = ["README.md", "CHANGELOG.md", "LICENSE", ".git"]
    for name in discouraged:
        if (skill_dir / name).exists():
            result.warn(f"Found '{name}' - skill directories typically don't need this file")

    # Check scripts are executable or have shebang
    scripts_dir = skill_dir / "scripts"
    if scripts_dir.exists():
        for script in scripts_dir.glob("*.py"):
            content = script.read_text()
            if not content.startswith("#!"):
                result.warn(f"Script '{script.name}' lacks shebang line")

        for script in scripts_dir.glob("*.sh"):
            content = script.read_text()
            if not content.startswith("#!"):
                result.warn(f"Script '{script.name}' lacks shebang line")


def validate_skill(path: Path) -> ValidationResult:
    """Main validation entry point."""
    result = ValidationResult()

    # Determine SKILL.md path
    if path.is_dir():
        skill_dir = path
        skill_file = path / "SKILL.md"
    else:
        skill_file = path
        skill_dir = path.parent

    if not skill_file.exists():
        result.error(f"SKILL.md not found at {skill_file}")
        return result

    content = skill_file.read_text()

    # Parse and validate
    metadata, body = parse_frontmatter(content)

    print(f"\nValidating: {skill_file}")
    print("-" * 50)

    # Run validations
    validate_name(metadata.get("name", ""), result)
    validate_description(metadata.get("description", ""), result)
    validate_body(body, result)
    validate_structure(skill_dir, result)

    return result


def main():
    # Determine path
    if len(sys.argv) > 1:
        path = Path(sys.argv[1])
    else:
        path = Path.cwd()

    # Handle if given a file or directory
    if path.is_file() and path.name == "SKILL.md":
        pass  # Use as-is
    elif path.is_dir():
        pass  # Will look for SKILL.md inside
    elif path.is_file():
        print(f"ERROR: Expected SKILL.md file, got: {path.name}")
        sys.exit(1)
    elif not path.exists():
        print(f"ERROR: Path does not exist: {path}")
        sys.exit(1)

    result = validate_skill(path)
    result.print_report()

    # Summary
    print()
    if result.is_valid():
        print(f"✓ Validation passed ({len(result.warnings)} warnings)")
        sys.exit(0)
    else:
        print(f"✗ Validation failed ({len(result.errors)} errors, {len(result.warnings)} warnings)")
        sys.exit(1)


if __name__ == "__main__":
    main()
