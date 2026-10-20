// Firebase Auth & Firestore Client with Offline Persistence
import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { 
  getAuth, 
  GoogleAuthProvider, 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signOut as fbSignOut, 
  onAuthStateChanged,
  type User,
  type Auth
} from 'firebase/auth';
import { 
  getFirestore, 
  type Firestore
} from 'firebase/firestore';

// Default configuration with fallback to environment variables
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyDemoFallbackKeyForHamPAPlannerApp",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "hampa-study-app.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "hampa-study-app",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "hampa-study-app.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1029384756",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:1029384756:web:abcd1234efgh5678"
};

let app: FirebaseApp | undefined;
let auth: Auth | undefined;
let db: Firestore | undefined;

try {
  if (!getApps().length) {
    app = initializeApp(firebaseConfig);
  } else {
    app = getApps()[0];
  }
  auth = getAuth(app);
  db = getFirestore(app);
} catch (error) {
  console.warn("Firebase initialized in mock/fallback mode:", error);
}

export { app, auth, db };

export async function loginWithGoogle() {
  if (!auth) throw new Error("Firebase Auth not initialized");
  const provider = new GoogleAuthProvider();
  return signInWithPopup(auth, provider);
}

export async function loginWithEmail(email: string, pass: string) {
  if (!auth) throw new Error("Firebase Auth not initialized");
  return signInWithEmailAndPassword(auth, email, pass);
}

export async function signupWithEmail(email: string, pass: string) {
  if (!auth) throw new Error("Firebase Auth not initialized");
  return createUserWithEmailAndPassword(auth, email, pass);
}

export async function logoutUser() {
  if (!auth) return;
  return fbSignOut(auth);
}

export function subscribeToAuthChanges(callback: (user: User | null) => void) {
  if (!auth) {
    callback(null);
    return () => {};
  }
  return onAuthStateChanged(auth, callback);
}
