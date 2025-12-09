### Group Number: 11
### Team Members: Allison Still, Jacob Mathew, Andy Osornio, Ethan Yu
### Name of the Project: Neiro
#### Dependencies: XCode 26.1.1, Swift 5, Firebase 12.4.0

#### Special Instructions:
- Just click "Log in" with the test credentials to enter the app
- If you're making an account, your password must be more than 6 characters. 
- Use dark mode for the Settings page, it's easier to read the text on some of the buttons
- Click the plus button in the top right of the Playlists tab to create a new playlist, then press an emoji to generate and save the playlist
- Click onto any of the existing playlists to see what songs are in them, the pencil to rename the playlist, and the X to delete the playlist.
- The group playlist feature requires two different accounts/simulators to be logged in. You cannot utilize this feature with two devices that are logged in to the same account on Neiro.
-   Neiro uses the Gemini API, and we use a Gemini API Key that is not committed for security. In order to run the project, please:
- 1. Duplicate the 'Secrets.example.xcconfig' file and rename it to 'Secrets.xcconfig'.
- 2. Add your Gemini API key instead of 'REPLACE_THIS' to GEMINI_API_KEY = REPLACE_THIS.
- 3. Clean and rebuild the project.

| Feature | Description | Release Planned | Release Actual | Deviations | Who/Percentage Worked On
| --- | --- | --- | --- | --- | --- | 
| Registration/Login Pages (including Spotify Login) | Allows user to create account and login either through Firebase or Spotify | Alpha | Alpha | Due to Spotify Developer API constraints, all new user emails must be verified and manually entered on the Developer Dashboard. As a result, new users cannot be added (with Spotify access) unless their email was previously added to the Dashboard access. | Allison (100%) | 
| UI | Colors, Buttons, Navigation, General On-App Design | Final | Final | None. | Ethan (100%) | 
| Group "Jam" Feature | Allows users to connect with other users through group codes to create shared playlists based on multiple emojis | Final | Final | None. | Andy (100%) | 
| Spotify API Integration (Playlist Generation) | Utilizing Spotify API to generate playlists based on emojis/moods (tempo, valence, energy, and keywords) | Beta | Final | Though the Spotify API was implemented during the Beta release, we optimized the logic that generates playlists during the final release. Playback feature on generated playlist is only available on iPhone and with a Spotify Premium Account. The Spotify app must be open and running in the background while Neiro is running in order for the playback feature to work. | Allison (100%) | 
| Settings | Features dark mode/light mode toggle, excluded and preferred artists and genres selection, playlist length selection, sign out button | Alpha | Beta | Preferred genres/artists was added after a suggestion was made on the grading feedback. Dark mode/light mode, excluded artists/genres, and the playlist length were all included in the Alpha release, but preferred genres/artists were not included until the beta release. | Ethan (100%) | 
| LLM Integration | Incorporates Gemini LLM to allow users to create or update playlists based on natural language input | Final | Final | Requires Gemini API Key - see comment below. | Allison (100%) | 
| Playlist History Screen | Allow users to see their past playlists, saved on Firestore| Beta | Beta | None | Jacob (60%) Andy (40%) | 
