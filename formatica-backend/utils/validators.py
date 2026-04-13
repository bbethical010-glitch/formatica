SUPPORTED_INPUT_FORMATS = {
    "docx", "doc", "odt", "rtf", "pptx", "ppt",
    "xlsx", "xls", "csv", "txt", "pdf", "html", "epub", "md"
}

SUPPORTED_OUTPUT_FORMATS = {
    "docx": ["pdf", "odt", "txt", "html", "rtf", "epub"],
    "doc":  ["pdf", "docx", "odt", "txt", "html", "rtf", "epub"],
    "odt":  ["pdf", "docx", "txt", "html", "rtf", "epub"],
    "rtf":  ["pdf", "docx", "txt", "html", "odt"],
    "pptx": ["pdf"],
    "ppt":  ["pdf", "pptx"],
    "xlsx": ["pdf", "csv"],
    "xls":  ["pdf", "xlsx", "csv"],
    "csv":  ["xlsx", "pdf"],
    "txt":  ["pdf", "docx", "html", "odt"],
    "pdf":  ["docx", "txt", "html"],
    "html": ["pdf", "docx", "odt", "txt", "rtf"],
    "epub": ["pdf", "docx", "odt", "txt", "html"],
    "md":   ["pdf", "docx", "odt", "txt", "html", "epub"],
}

DANGEROUS_CHARS = set(";") | set("&|$`>")


def is_valid_url(url: str) -> bool:
    """Returns True if the URL is safe and starts with http:// or https://."""
    if not url or len(url) > 2048:
        return False
    if not (url.startswith("https://") or url.startswith("http://")):
        return False
    if "\x00" in url:
        return False
    if any(ch in url for ch in DANGEROUS_CHARS):
        return False
    return True


def is_safe_filename(filename: str) -> bool:
    """Returns True if the filename is safe for filesystem use."""
    if not filename or len(filename) > 255:
        return False
    if "\x00" in filename:
        return False
    if ".." in filename or "/" in filename or "\\" in filename:
        return False
    return True
