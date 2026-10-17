# Playwright Framework

Playwright end-to-end framework using Page Object Model, fixtures, centralized test data, and CI execution.

## Project Structure

- `pages/` - page object classes
- `tests/` - test specs
- `fixtures/` - custom Playwright fixtures
- `test-data/` - test input and expected values
- `utils/` - shared helpers and environment configuration
- `.github/workflows/` - CI pipeline

## Setup

1. Install dependencies:
   - `npm ci`
2. Install Playwright browser:
   - `npx playwright install chromium`
3. Optional environment setup:
   - copy `.env.example` to `.env`
   - set `BASE_URL` if needed

## Run Tests

- All tests:
  - `npm test`
- Chromium only:
  - `npm run test:chromium`
- Login spec only:
  - `npm run test:login`
- UI mode:
  - `npm run test:ui`
- HTML report:
  - `npm run report`

## Standards Followed

- Page Object Model
- Reusable fixture-based setup
- Centralized test data
- Failure artifacts (screenshot/video/trace)
- CI execution via GitHub Actions
