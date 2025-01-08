# Carbon Emission Calculator

This is a Flutter application that calculates carbon emissions based on cargo weight and travel distance using the Google Maps API. The app integrates with Supabase for user management and authentication.

I have used google's Project IDX to create this flutter application. you can learn more about that [here.](https://idx.google.com/)
The environment set up details can be found in the [.idx](https://github.com/PhoenixAlpha23/CarbonCourier/tree/main/.idx) folder.

## Table of Contents
1. [Overview](#overview)
2. [Features](#features)
3. [Technologies Used](#technologies-used)
4. [Setup Instructions](#setup-instructions)
5. [Folder Structure](#folder-structure)
6. [Usage](#usage)
7. [Future Improvements](#future-improvements)

---

## Overview
This project is designed to provide an estimate of carbon emissions for trips based on input factors:
- Distance between two locations (calculated via Google Maps API)
- Cargo weight entered by the user

The application is ideal for logistics, delivery services, and eco-conscious users looking to monitor environmental impact.

Supabase is used to handle user authentication and management.

---

## Features
- **User Authentication**: Login and registration powered by Supabase.
- **Distance Calculation**: Calculates travel distance using Google Maps API.
- **Carbon Emission Estimation**: Computes carbon emissions based on cargo weight and travel distance.
- **Interactive Map**: Visualize start and end points on Google Maps.

---

## Technologies Used
- **Flutter** (UI development for cross-platform compatibility)
- **Google Maps API** (distance and map visualization)
- **Supabase** (user management and authentication)

---

## Setup Instructions
Follow these steps to set up the project locally:

### Prerequisites
- Flutter SDK installed ([Flutter Installation Guide](https://docs.flutter.dev/get-started/install))
- Google Cloud Platform project with Maps API enabled ([Get an API Key](https://developers.google.com/maps/documentation/javascript/get-api-key))
- Supabase project set up ([Supabase Quickstart](https://supabase.com/docs/guides/with-flutter))

### Steps
1. Clone this repository:
   ```bash
   git clone <https://github.com/PhoenixAlpha23/CarbonCourier/tree/main>
   cd <lib>
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Add API keys:
   - Create a `.env` file in the root folder.
   - Add your Google Maps API key and Supabase credentials.
   ```plaintext
   GOOGLE_MAPS_API_KEY=your_google_maps_key_here
   SUPABASE_URL=your_supabase_url_here
   SUPABASE_ANON_KEY=your_supabase_anon_key_here
   ```

4. Run the app:
   ```bash
   flutter run
   ```

---

## Folder Structure
```plaintext
project-folder/
├── assets/                 # App images and icons
├── lib/                    # Main source code
│   ├── main.dart           # Entry point of the app
│   ├── pages/              # Screens for the app
│   ├── services/           # API and backend integrations
│   ├── widgets/            # Reusable components
├── pubspec.yaml            # Project dependencies
└── README.md               # Project documentation
```

---

## Usage
1. **Run the App**
   - Launch the app on a simulator/emulator or physical device.

2. **Log In / Sign Up**
   - Register or log in using Supabase authentication.

3. **Calculate Carbon Emissions**:
   - Enter cargo weight.
   - Select the starting point and destination on the map.
   - View the calculated distance and carbon emissions.

---

## Future Improvements
- **Data Storage**: Save previous trips and carbon calculations in a database.
- **Advanced Estimations**: Incorporate fuel types and vehicle efficiency for more accurate emissions.
- **UI Enhancements**: Improve the interface for better user experience.
- **Analytics Dashboard**: Display visual reports on carbon footprints over time.

---

## Contribution
Contributions are welcome! If you find any bugs or have suggestions, feel free to open an issue or submit a pull request.

---

## License
This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.
