"""Windows paths for filesystem access and conventional paths for links."""
import os
from pathlib import Path


def filesystem_path(path):
    path = Path(os.path.abspath(path))
    if os.name != 'nt':
        return path
    value = str(path)
    if value.startswith('\\\\?\\'):
        return path
    if value.startswith('\\\\'):
        return Path('\\\\?\\UNC\\' + value[2:])
    return Path('\\\\?\\' + value)


def display_path(path):
    value = str(path)
    if os.name == 'nt':
        if value.startswith('\\\\?\\UNC\\'):
            value = '\\\\' + value[8:]
        elif value.startswith('\\\\?\\'):
            value = value[4:]
    return Path(value)
