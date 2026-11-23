#!/usr/bin/env python3
"""Incrementally refresh the local short-drama RAG index."""

from rag_core import update_index_cli


if __name__ == "__main__":
    raise SystemExit(update_index_cli())
