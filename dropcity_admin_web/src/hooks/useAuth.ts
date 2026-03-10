import { useAuthStore } from '@/lib/store/authStore';
import { useEffect, useState } from 'react';
import { auth } from '@/lib/firebase/config';
import { onAuthStateChanged } from 'firebase/auth';

export const useAuth = () => {
  const { user, setUser, setLoading } = useAuthStore();
  const [isChecking, setIsChecking] = useState(true);

  useEffect(() => {
    const unsubscribe = onAuthStateChanged(auth, async (firebaseUser) => {
      if (firebaseUser) {
        // Fetch user data from Firestore
        setUser({
          id: firebaseUser.uid,
          email: firebaseUser.email || '',
          name: firebaseUser.displayName || 'Admin',
          role: 'admin',
          createdAt: new Date(),
        });
      } else {
        setUser(null);
      }
      setLoading(false);
      setIsChecking(false);
    });

    return () => unsubscribe();
  }, [setUser, setLoading]);

  return { user, isChecking };
};
