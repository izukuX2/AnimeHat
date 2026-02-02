# Animeify API Analysis Summary

This document summarizes the findings from the `animeify.txt` file, which contains raw data and API structures for the Animeify app.

## 1. Data Structure Overview

The file consists of several key sections:

- **`LatestEpisodes`**: A list of recently released episodes. Each entry contains:
  - **`Anime`**: Metadata like title (EN/AR/JP), genres, studio, score, thumbnail, and rankings.
  - **`Episode`**: Episode number, unique ID (`eId`), and stream links.
- **`Broadcast`**: Anime airing schedule for various days.
- **`Premiere`**: Lists showing newly premiered series for the current season (Winter 2026).
- **`Configurations`**: Global application settings, including:
  - App update URLs (`animeify-app.com/downloads/...`)
  - Ad configuration (AppLovin, StartApp, Google Ad Units).
  - Social media links (Facebook, YouTube, Instagram).
  - List of supported studios and years.
- **`UpdatesChart`**: Quick stats (count of new episodes, anime, characters, and news).

## 2. API Endpoints (v4)

The file reveals several active API endpoints used by the app:

### Configuration API
- **URL**: `https://animeify.net/animeify/apis_v4/configuration.php`
- **Method**: `POST`
- **Content-Type**: `application/x-www-form-urlencoded`

### Load Servers (Stream Links)
- **URL**: `https://animeify.net/animeify/apis_v4/anime/load_servers.php`
- **Method**: `POST`
- **Parameters**: `UserId`, `AnimeId`, `Episode`, `AnimeType`, `Token`
- **Response**: Contains player links (`OKLink`, `MALink`, `FRLink`, etc.) and episode statistics.

### Load Anime List (Search/Filter)
- **URL**: `https://animeify.net/animeify/apis_v4/anime/load_anime_list_v2.php`
- **Method**: `POST`
- **Parameters**: `UserId`, `Language`, `FilterType` (e.g., `SEARCH`), `FilterData` (e.g., `naruto`), `Type`, `From`, `Token`

## 3. Streaming Server Mapping (Identified)

| Key | Description / Predicted Server |
| --- | --- |
| `OKLink` | ok.ru |
| `MALink` | MyAnimeList / Multi-server? |
| `FRLink` | Firedrop / French server? |
| `GDLink` | Google Drive |
| `SVLink` | Standard View / Internal? |

## 4. Key Observation: Token Based
Most POST requests require a `Token` (e.g., `8cnY80AZSbUCmR26Vku1VUUY4`), which is likely obtained via a login or session initialization endpoint.
