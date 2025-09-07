// Firebase SDK
import { initializeApp } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-app.js";
import { getFirestore } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-firestore.js";
import { getAuth } from "https://www.gstatic.com/firebasejs/11.0.1/firebase-auth.js";

const firebaseConfig = {
  apiKey: "AIzaSyBiGF-5w-nkhYEW7_AoJS-f18f6PnOCRt0",
  authDomain: "finalproject-6bebe.firebaseapp.com",
  projectId: "finalproject-6bebe",
  storageBucket: "finalproject-6bebe.appspot.com",
  messagingSenderId: "75244933477",
  appId: "1:75244933477:web:d37e34caf570eda3dd918c",
  measurementId: "G-ZS57ZGFVJW"
};

const app = initializeApp(firebaseConfig);
export const db = getFirestore(app);
export const auth = getAuth(app);
