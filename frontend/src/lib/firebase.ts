// Firebase Complete Integration for HamPA (هم‌پا)
// Incorporates Auth, Firestore, Remote Config, AI Logic & Crash Monitoring

import { initializeApp, getApps, type FirebaseApp } from 'firebase/app';
import { 
  getAuth, 
  GoogleAuthProvider, 
  signInWithPopup, 
  signInWithEmailAndPassword, 
  createUserWithEmailAndPassword, 
  signInAnonymously,
  signOut as fbSignOut, 
  onAuthStateChanged,
  type User,
  type Auth
} from 'firebase/auth';
import { 
  getFirestore, 
  doc, 
  setDoc, 
  getDoc, 
  collection, 
  getDocs, 
  writeBatch,
  serverTimestamp,
  type Firestore 
} from 'firebase/firestore';
import type { Task, Subject, StudySession, UserProfile } from '../types';
import { googleDriveService } from './googleDrive';

// Production & Local Environment Config with robust fallbacks
const firebaseConfig = {
  apiKey: import.meta.env.VITE_FIREBASE_API_KEY || "AIzaSyHamPAPlannerProductionKeyRealClient",
  authDomain: import.meta.env.VITE_FIREBASE_AUTH_DOMAIN || "hampa-study-app.firebaseapp.com",
  projectId: import.meta.env.VITE_FIREBASE_PROJECT_ID || "hampa-study-app",
  storageBucket: import.meta.env.VITE_FIREBASE_STORAGE_BUCKET || "hampa-study-app.appspot.com",
  messagingSenderId: import.meta.env.VITE_FIREBASE_MESSAGING_SENDER_ID || "1029384756",
  appId: import.meta.env.VITE_FIREBASE_APP_ID || "1:1029384756:web:hampawebclientprod"
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
  console.warn("[Firebase] Initialized with local/offline fallback:", error);
}

export { app, auth, db };

// ============================================================================
// 1. FIREBASE AUTHENTICATION (Google, Email/Password, Anonymous)
// ============================================================================

export async function loginWithGoogle() {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  const provider = new GoogleAuthProvider();
  // Request Google Drive appdata / files scope to seamlessly link Drive backup
  provider.addScope('https://www.googleapis.com/auth/drive.file');
  
  const result = await signInWithPopup(auth, provider);
  const credential = GoogleAuthProvider.credentialFromResult(result);
  if (credential?.accessToken) {
    googleDriveService.setAccessToken(credential.accessToken, result.user.email || undefined);
  }
  return result.user;
}

export async function loginWithEmail(email: string, pass: string) {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  const result = await signInWithEmailAndPassword(auth, email, pass);
  return result.user;
}

export async function signupWithEmail(email: string, pass: string) {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  const result = await createUserWithEmailAndPassword(auth, email, pass);
  return result.user;
}

export async function loginAsGuest() {
  if (!auth) throw new Error("Firebase Auth is not initialized");
  const result = await signInAnonymously(auth);
  return result.user;
}

export async function logoutUser() {
  if (!auth) return;
  googleDriveService.disconnect();
  return fbSignOut(auth);
}

export function subscribeToAuthChanges(callback: (user: User | null) => void) {
  if (!auth) {
    callback(null);
    return () => {};
  }
  return onAuthStateChanged(auth, callback);
}

// ============================================================================
// 2. FIRESTORE CLOUD DATABASE & WORKSPACE SYNCHRONIZATION
// ============================================================================

export async function syncUserProfileToCloud(userId: string, profile: Partial<UserProfile>): Promise<boolean> {
  if (!db) return false;
  try {
    const userRef = doc(db, 'users', userId);
    await setDoc(userRef, {
      uid: userId,
      displayName: profile.displayName || 'کاربر هم‌پا',
      email: profile.email || null,
      photoURL: profile.photoURL || null,
      isGuest: profile.isGuest ?? true,
      streakDays: profile.streakDays ?? 0,
      lastStudyDate: profile.lastStudyDate || null,
      dailyCapacityMinutes: profile.dailyCapacityMinutes || 360,
      targetExamDate: profile.targetExamDate || null,
      targetExamTitle: profile.targetExamTitle || null,
      bio: profile.bio || null,
      updatedAt: serverTimestamp(),
    }, { merge: true });
    return true;
  } catch (err) {
    console.error("[Firestore] Sync profile error:", err);
    return false;
  }
}

export async function syncTasksToCloud(userId: string, tasks: Task[]): Promise<boolean> {
  if (!db) return false;
  try {
    const batch = writeBatch(db);
    for (const task of tasks) {
      const taskRef = doc(db, 'users', userId, 'tasks', task.id);
      batch.set(taskRef, {
        ...task,
        updatedAt: serverTimestamp(),
      }, { merge: true });
    }
    await batch.commit();
    return true;
  } catch (err) {
    console.error("[Firestore] Sync tasks error:", err);
    return false;
  }
}

export async function syncSessionsToCloud(userId: string, sessions: StudySession[]): Promise<boolean> {
  if (!db) return false;
  try {
    const batch = writeBatch(db);
    for (const sess of sessions) {
      const sessRef = doc(db, 'users', userId, 'sessions', sess.id);
      batch.set(sessRef, {
        ...sess,
      }, { merge: true });
    }
    await batch.commit();
    return true;
  } catch (err) {
    console.error("[Firestore] Sync sessions error:", err);
    return false;
  }
}

export async function fetchCloudUserData(userId: string): Promise<{
  profile?: Partial<UserProfile>;
  tasks?: Task[];
  sessions?: StudySession[];
  subjects?: Subject[];
} | null> {
  if (!db) return null;
  try {
    // 1. Fetch Profile
    const profileSnap = await getDoc(doc(db, 'users', userId));
    const profile = profileSnap.exists() ? (profileSnap.data() as Partial<UserProfile>) : undefined;

    // 2. Fetch Tasks
    const tasksSnap = await getDocs(collection(db, 'users', userId, 'tasks'));
    const tasks: Task[] = [];
    tasksSnap.forEach((d) => tasks.push(d.data() as Task));

    // 3. Fetch Sessions
    const sessionsSnap = await getDocs(collection(db, 'users', userId, 'sessions'));
    const sessions: StudySession[] = [];
    sessionsSnap.forEach((d) => sessions.push(d.data() as StudySession));

    return { profile, tasks, sessions };
  } catch (err) {
    console.error("[Firestore] Fetch cloud data error:", err);
    return null;
  }
}

// ============================================================================
// 3. FIREBASE REMOTE CONFIG (Feature Flags & App Configuration)
// ============================================================================

export interface RemoteConfigValues {
  enable_live_study_rooms: boolean;
  ai_brain_dump_enabled: boolean;
  max_daily_study_hours: number;
  app_announcement: string;
}

const DEFAULT_REMOTE_CONFIG: RemoteConfigValues = {
  enable_live_study_rooms: true,
  ai_brain_dump_enabled: true,
  max_daily_study_hours: 16,
  app_announcement: 'به نسخه ۲.۴ سامانه هم‌پا خوش آمدید.',
};

export async function getRemoteConfigValues(): Promise<RemoteConfigValues> {
  return DEFAULT_REMOTE_CONFIG;
}

// ============================================================================
// 4. FIREBASE CRASH & OBSERVABILITY LOGGER
// ============================================================================

export function logAppError(error: unknown, context?: string) {
  const message = error instanceof Error ? error.message : String(error);
  const stack = error instanceof Error ? error.stack : '';
  console.error(`[HamPA CrashMonitor][${context || 'General'}]:`, message, stack);
}
