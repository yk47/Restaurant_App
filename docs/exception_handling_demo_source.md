# Exception Handling Demonstration (Restaurant App)

Date: 24 April 2026

## 1) What this means in plain language
When something goes wrong (no internet, bad server response, invalid JSON, etc.),
the app does not crash. Instead, it converts the technical error into a user-friendly
message and shows a retry action.

## 2) Exception model used in this app
- `AppException(message, statusCode?)`
  - A single app-level exception type.
  - Keeps a readable message and optional HTTP status code.

- `ExceptionHandler.handle(error)`
  - If the incoming error is already `AppException`, return it as-is.
  - Otherwise return a safe fallback: `Something went wrong. Please try again.`

## 3) Where exceptions are created
In `RestaurantApiClient._requestJson(...)`:
- HTTP status not in 2xx
  - Throws `AppException` with message parsed from body (if available),
    otherwise `Request failed with status <code>.`
- `SocketException`
  - Throws `AppException('No internet connection.')`
- `HttpException`
  - Throws `AppException(error.message)`
- `FormatException`
  - Throws `AppException('Unexpected response format.')`
- Any unknown error
  - Normalized through `ExceptionHandler.handle(error)`

## 4) Where exceptions are shown to users
In `RestaurantListController`:
- During `loadRestaurants(...)` and `loadMore()`
- `catch (error)` converts error to message:
  - `errorMessage.value = ExceptionHandler.handle(error).message`
- UI in `RestaurantListScreen`:
  - If there is an error and no list data, it shows `ErrorView` with retry.

## 5) Human-readable scenario demo

### Scenario A: No internet
1. User opens app or searches restaurants.
2. Request fails with `SocketException`.
3. API layer throws `AppException('No internet connection.')`.
4. Controller catches and stores the message.
5. UI shows an error state with Retry.

User sees: **No internet connection.**

### Scenario B: Server returns 500
1. Request returns status 500.
2. API layer tries reading an error message from response JSON.
3. If no readable message, it uses `Request failed with status 500.`
4. Controller sends the message to UI.
5. UI shows retry option.

User sees: **Request failed with status 500.** (or server-provided message)

### Scenario C: Malformed JSON response
1. Server responds with invalid JSON format.
2. `jsonDecode` throws `FormatException`.
3. API layer maps to `AppException('Unexpected response format.')`.
4. Controller updates `errorMessage`.
5. UI shows fallback error and retry.

User sees: **Unexpected response format.**

## 6) Why this is good for users
- Consistent and understandable messages.
- App stays stable under failures.
- Retry path is immediately available.
- Internal exceptions are hidden from end users.

## 7) Improvement ideas (optional)
- Add localization for error messages.
- Add structured logging/analytics per error type.
- Show partial cached data when network fails.
- Add a distinct timeout message (connect vs. read timeout).
