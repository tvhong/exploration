# google-flights-mcp

> An MCP server that exposes Google Flights search (via the `fast-flights` scraping library) as tools, resources, and prompts for LLM clients like Claude Desktop.

## 5C Overview

### Category

MCP (Model Context Protocol) server plugin. Python, targeting the Claude Desktop / MCP ecosystem. Target users: developers or enthusiasts who want to give Claude the ability to search real flight data in conversation.

### Context

MCP is Anthropic's open protocol for giving LLMs structured access to external tools and data. The flight search space is dominated by commercial APIs (Amadeus, Skyscanner, Google Flights) that require API keys and often paid plans. The `fast-flights` library is a Python scraper that reverse-engineers Google Flights' Protobuf-encoded URL parameters to fetch real pricing and schedule data without an API key.

### Contribution

Wraps `fast-flights` into an MCP-compatible server so any MCP-enabled client can search flights, look up airport codes, and generate travel plan prompts — all without a commercial API key. The combination of the unofficial scraper with the MCP wrapper is the distinguishing feature; there is no official Google Flights MCP server.

### Correctness

**Experimental / early-stage.** Version `0.1.0`, only 2 commits, no tests, no CI, no badges. The `main.py` entry point is a stub (`print("Hello from google-flights-mcp!")`), suggesting the project was scaffolded with a tool and the real logic lives in `src/flights-mcp-server.py`. The code relies on `aiohttp` but it is not listed in `pyproject.toml` dependencies — a latent install failure. The airport database is fetched at startup from an external GitHub URL, making cold-start reliability dependent on network availability and an undeclared dependency. Error handling exists but is inconsistent (some paths return error strings, others raise). The underlying `fast-flights` scraper is inherently fragile against Google-side changes.

### Clarity

README is clear and concise — covers installation, Claude Desktop integration, MCP Inspector usage, and example queries. The main server file (`src/flights-mcp-server.py`) is well-commented with descriptive docstrings on every tool and resource. Onboarding is straightforward for anyone familiar with Claude Desktop configuration. The disconnect between `main.py` (stub) and the actual server file (`src/flights-mcp-server.py`) is mildly confusing, and the `src/google_flights_mcp/__init__.py` is also a stub — the package structure appears unfinished.

## Main components

| Component | What it does | Location |
|---|---|---|
| MCP server init | Creates the `FastMCP` instance named "Flight Planner" | `src/flights-mcp-server.py:106` |
| `search_flights` tool | Searches one-way or round-trip flights via `fast-flights`; validates inputs, builds `FlightData`/`Passengers` objects, calls `get_flights()` | `src/flights-mcp-server.py:111` |
| `airport_search` tool | Searches the in-memory airport dict by code or name fragment; returns up to 20 matches | `src/flights-mcp-server.py:291` |
| `get_travel_dates` tool | Computes departure/return date strings from "days from now" and "trip length" offsets | `src/flights-mcp-server.py:329` |
| `update_airports_database` tool | Async tool to re-fetch the airport CSV from GitHub and refresh the in-memory dict | `src/flights-mcp-server.py:363` |
| `airports://all` resource | Returns first 100 airports from the in-memory dict | `src/flights-mcp-server.py:400` |
| `airports://{code}` resource | Looks up a single airport by IATA code | `src/flights-mcp-server.py:412` |
| `plan_trip` prompt | Generates a destination planning prompt that includes a request to search flights | `src/flights-mcp-server.py:420` |
| `compare_destinations` prompt | Generates a comparison prompt for two destinations with a flight search request | `src/flights-mcp-server.py:433` |
| Airport data layer | Loads airports from a JSON cache file or fetches from GitHub CSV on startup | `src/flights-mcp-server.py:44–103` |

## How it works & data flow

```
Claude Desktop / MCP client
        │
        │  MCP protocol (stdio)
        ▼
  FastMCP server ("Flight Planner")
        │
        ├─ Tool: search_flights
        │       │
        │       ├─ Validates IATA codes against in-memory airports dict
        │       ├─ Builds FlightData + Passengers objects
        │       └─ Calls fast_flights.get_flights()
        │               │
        │               └─ Scrapes Google Flights (Protobuf URL → HTTP)
        │                       │
        │                       └─ Returns Result with flights list
        │
        ├─ Tool: airport_search  ──► searches airports dict
        ├─ Tool: get_travel_dates ──► date arithmetic only (no I/O)
        ├─ Tool: update_airports_database
        │       └─ aiohttp GET → GitHub CSV → parse → update dict + cache
        │
        ├─ Resource: airports://all / airports://{code}  ──► read dict
        └─ Prompt: plan_trip / compare_destinations  ──► static text
```

**Startup sequence:**
1. Server loads airport data: checks `airports_cache.json` on disk; if missing, fetches CSV from GitHub (`airportsdata` repo).
2. `FastMCP.run()` starts listening on stdio for MCP messages.
3. On tool call, `search_flights` lazily imports `fast_flights` (avoids startup crash if library is missing) and delegates to the scraper.

---
*Explored on 2026-03-17 · ~6 files read*
