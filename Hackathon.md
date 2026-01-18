# Tide Party

Discover and collect local marine life while learning how to protect our oceans.

## Inspiration

Hey! We're TideParty, but our names are Oleg and Anthony. We LOVE tide pooling in Santa Cruz. It’s a relaxing activity that many people enjoy, and Santa Cruz is an ideal place for it thanks to its rocky cliffs and abundant marine life. However, when people go tide pooling, they often don’t know what they’re looking at. We built this app to help people identify marine organisms in real time, learn about them, and gain a deeper appreciation for ocean conservation.

## What it does

Tide Party is an interactive mobile app that turns tide pooling into a fun, educational experience:

- Discover and navigate to local tide pooling spots
- Identify marine life in real time by pointing your camera at a sea creature
- Take photos and collect the creatures you find
- Learn detailed information about each species
- Earn badges by collecting creatures and answering quiz questions
- Join party rooms with friends and race to find the most creatures

## How we built it

We built the app using **SwiftUI** for the frontend and **Firebase** for backend storage and real-time features. For marine life recognition, we trained a custom machine learning model using **PyTorch** and converted it into an Apple-compatible Core ML model for on-device inference.

## Challenges we ran into

Training the model was our biggest challenge. Due to the limited available image data, we relied heavily on image augmentation to improve performance. Collecting and labeling data was also difficult, and early versions of the model suffered from underfitting. After extensive preprocessing and training, we were able to build a generalized model capable of accurately classifying Santa Cruz tide pool marine life with **94% accuracy**.

## Accomplishments that we’re proud of

We’re proud that we were able to fully realize our original vision, from real-time classification to multiplayer features. Achieving high model accuracy, building a polished UI, and designing a friendly mascot to enhance the user experience were major wins for us.

## What we learned

We learned how to work quickly and effectively under pressure, how to design thoughtful UI/UX animations and interactions in Swift, and how to train and deploy a machine learning model within a real mobile application.

## What’s next for Tide Party

Next, we want to release Tide Party to real users. It would be especially impactful for school field trips, where students can compete to discover marine life together. We also plan to:

- Expand and improve our tide pool location map
- Train a more robust model to classify additional species
- Support multiple creature detections in a single frame
- Add online leaderboards and public party rooms
- Partner with charities focused on local ocean conservation
