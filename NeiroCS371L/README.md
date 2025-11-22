## Contributions:

#### Allison Still (25%):
- Login screen
- Registration screen

#### Jacob Mathew (25%):
- Floating navigation bar
- Playlist overview page

#### Andy Osornio (25%):
- Emoji option segues
- Detailed playlist look

#### Ethan Yu (25%):
- Settings screen
- Settings features (dark mode, excluded music, playlist length)


## Differences:
- Group playlists/networking will be in the beta (wasn't really specified either way in the design doc)
- Firebase integration for playlists to users will be in the beta (also wasn't specified)
- Robust app-wide integration of settings will be in the beta (dark mode, excluded/preferred genres, etc.)


## Comments:
- Just click "Log in" with the test credentials to enter the app
- If you're making an account, your password must be more than 6 characters. We will display these errors in the beta
- Use dark mode for the Settings page, it's easier to read the text on some of the buttons
- Click the plus button in the top right of the Playlists tab to create a new playlist, then press an emoji to generate and save the playlist
- Click onto any of the existing playlists to see what songs are in them, the pencil to rename the playlist, and the X to delete the playlist

- New Comment for Final Release:
-   Neiro uses the Gemini API, and we use a Gemini API Key that is not committed for security. In order to run the project, please:
- 1. Duplicate the 'Secrets.example.xcconfig' file and rename it to 'Secrets.xcconfig'.
- 2. Add your Gemini API key instead of 'REPLACE_THIS' to GEMINI_API_KEY = REPLACE_THIS.
- 3. Clean and rebuild the project.
