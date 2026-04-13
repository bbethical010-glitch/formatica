import sys
import re

file_path = '/Users/prathampandey/Desktop/mediadoc-studio/packages/desktop/src-tauri/src/lib.rs'

with open(file_path, 'r') as f:
    content = f.read()

# Replace hardcoded python in get_setup_status (already updated in my previous attempt, but for completeness)
# Actually, I should just make sure python_path() is used everywhere.

# Find all occurrences of Command::new("python") and std::process::Command::new("python")
# and replace them with usage of python_path()

def replace_python(match):
    prefix = match.group(1)
    return f'let py = python_path();\n{prefix}Command::new(py)'

# We need to be careful with closures and indentation.
# A simpler way is to replace 'Command::new("python")' with 'Command::new(python_path())' 
# if we don't mind the overhead or if it's in a context where it's fine.
# But python_path() is not a 'const'.

# Let's use a more surgical approach for each major block.

# 1. Update all std::process::Command::new("python")
content = content.replace('std::process::Command::new("python")', 'std::process::Command::new(python_path())')

# 2. Update all Command::new("python") EXCEPT inside python_path() itself
# The one in python_path() uses find_bin("python"), not Command::new("python").
# Wait, find_bin uses Command::new(cmd).arg(bin).
# So Command::new("python") should be replaced with Command::new(python_path()).

content = content.replace('Command::new("python")', 'Command::new(python_path())')

with open(file_path, 'w') as f:
    f.write(content)

print("Replacement complete.")
