import os
import time
import asyncio

TMP_DIR = "/app/tmp"


async def start_cleanup_loop():
    """Runs forever, deleting temp files older than 30 seconds every 15 seconds."""
    while True:
        try:
            for filename in os.listdir(TMP_DIR):
                filepath = os.path.join(TMP_DIR, filename)
                if os.path.isfile(filepath):
                    try:
                        mtime = os.path.getmtime(filepath)
                        if time.time() - mtime > 30:
                            os.remove(filepath)
                    except PermissionError as e:
                        print(f"Cleanup permission error: {e}")
                    except OSError as e:
                        print(f"Cleanup OS error: {e}")
        except FileNotFoundError:
            pass
        await asyncio.sleep(15)


def get_tmp_path(filename: str) -> str:
    """Returns the full path to a file in the temp directory."""
    return f"{TMP_DIR}/{filename}"
