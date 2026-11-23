#!/usr/bin/env python3
"""Build or incrementally refresh the local short-drama RAG index."""

from rag_core import build_index_cli


if __name__ == "__main__":
    raise SystemExit(build_index_cli())
