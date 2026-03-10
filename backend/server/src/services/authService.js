const { supabase } = require('../utils/supabase');
const { db } = require('../utils/firebase');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

class AuthService {
  // Helper: Check database connection
  static ensureDb() {
    if (!db) {
      throw new Error('Database connection not initialized. Check Firebase credentials in .env');
    }
  }

  // Helper: Cleanup orphaned Supabase user
  static async cleanupSupabaseUser(userId) {
    try {
      await supabase.auth.admin.deleteUser(userId);
      console.log(`⚠️  Cleaned up orphaned Supabase user: ${userId}`);
    } catch (cleanupError) {
      console.error(`Failed to cleanup user ${userId}:`, cleanupError.message);
    }
  }

  // Customer Registration
  static async registerCustomer({ email, password, fullName, phoneNumber }) {
    try {
      // Validate database connection
      this.ensureDb();

      console.log(`📝 Registering customer: ${email}`);

      // Register in Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
      });

      if (authError) {
        console.error('❌ Supabase signup error:', authError);
        throw new Error(`Supabase auth error: ${authError.message || JSON.stringify(authError)}`);
      }

      if (!authData || !authData.user) {
        throw new Error('No user data returned from Supabase signup');
      }

      const userId = authData.user.id;
      if (!userId) {
        throw new Error('Failed to get user ID from Supabase');
      }

      console.log(`✅ User created in Supabase: ${userId}`);

      // Parse full name into first and last
      const nameParts = (fullName || '').trim().split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';

      // Create customer profile in Firestore
      try {
        await db.collection('customers').doc(userId).set({
          id: userId,
          email,
          firstName,
          lastName,
          phoneNumber,
          profileImageUrl: '',
          address: '',
          createdAt: new Date(),
          rating: 0,
          totalOrders: 0,
          verified: false,
        });
        console.log(`✅ Customer profile created in Firestore: ${userId}`);
      } catch (firestoreError) {
        // Cleanup orphaned Supabase user if Firestore write fails
        console.error('❌ Firestore error:', firestoreError);
        await this.cleanupSupabaseUser(userId);
        throw new Error(`Failed to create customer profile: ${firestoreError.message}`);
      }

      // Generate JWT token for immediate login after registration
      const token = jwt.sign(
        { uid: userId, email, userType: 'customer' },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
      );

      return {
        success: true,
        message: 'Customer registered successfully',
        userId,
        email,
        fullName,
        token,
        user: {
          id: userId,
          email,
          firstName,
          lastName,
          phoneNumber,
          userType: 'customer',
        },
      };
    } catch (error) {
      console.error('❌ Registration error:', error);
      throw error;
    }
  }

  // Courier Registration
  static async registerCourier({
    email,
    password,
    fullName,
    phoneNumber,
    vehicleType,
    vehicleNumber,
    licenseNumber,
  }) {
    try {
      // Validate database connection
      this.ensureDb();

      // Register in Supabase Auth
      const { data: authData, error: authError } = await supabase.auth.signUp({
        email,
        password,
      });

      if (authError) {
        throw new Error(`Supabase auth error: ${authError.message}`);
      }

      const userId = authData.user.id;
      if (!userId) {
        throw new Error('Failed to get user ID from Supabase');
      }

      // Parse full name into first and last
      const nameParts = (fullName || '').trim().split(' ');
      const firstName = nameParts[0] || '';
      const lastName = nameParts.slice(1).join(' ') || '';

      // Create courier profile in Firestore
      try {
        await db.collection('couriers').doc(userId).set({
          id: userId,
          email,
          firstName,
          lastName,
          phoneNumber,
          vehicleType,
          vehicleNumber,
          licenseNumber,
          profileImageUrl: '',
          rating: 0,
          totalDeliveries: 0,
          isOnline: false,
          currentLocation: null,
          createdAt: new Date(),
          verified: false,
          documentsVerified: false,
        });
      } catch (firestoreError) {
        // Cleanup orphaned Supabase user if Firestore write fails
        await this.cleanupSupabaseUser(userId);
        throw new Error(`Failed to create courier profile: ${firestoreError.message}`);
      }

      // Generate JWT token for immediate login after registration
      const token = jwt.sign(
        { uid: userId, email, userType: 'courier' },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
      );

      return {
        success: true,
        message: 'Courier registered successfully',
        userId,
        email,
        fullName,
        token,
        user: {
          id: userId,
          email,
          firstName,
          lastName,
          phoneNumber,
          vehicleType,
          vehicleNumber,
          licenseNumber,
          userType: 'courier',
        },
      };
    } catch (error) {
      throw error;
    }
  }

  // Login
  static async login(email, password) {
    try {
      // Validate database connection
      this.ensureDb();

      const { data, error } = await supabase.auth.signInWithPassword({
        email,
        password,
      });

      if (error) {
        throw new Error(`Login failed: ${error.message}`);
      }

      const user = data.user;
      const session = data.session;

      // Fetch user type (customer or courier)
      const customerDoc = await db.collection('customers').doc(user.id).get();
      const courierDoc = await db.collection('couriers').doc(user.id).get();

      let userType = 'customer';
      let userData = null;

      if (customerDoc.exists) {
        userType = 'customer';
        userData = customerDoc.data();
      } else if (courierDoc.exists) {
        userType = 'courier';
        userData = courierDoc.data();
      } else {
        throw new Error('User profile not found in database');
      }

      // Generate JWT token with uid property (not userId)
      const token = jwt.sign(
        { uid: user.id, email: user.email, userType },
        process.env.JWT_SECRET || 'your-secret-key',
        { expiresIn: process.env.JWT_EXPIRE || '7d' }
      );

      return {
        success: true,
        message: 'Login successful',
        token,
        user: {
          id: user.id,
          email: user.email,
          userType,
          ...userData,
        },
      };
    } catch (error) {
      throw error;
    }
  }

  // Logout
  static async logout(token) {
    try {
      const { error } = await supabase.auth.signOut();
      if (error) throw error;

      return { success: true, message: 'Logout successful' };
    } catch (error) {
      throw error;
    }
  }

  // Get Current User
  static async getCurrentUser(userId) {
    try {
      // Validate database connection
      this.ensureDb();

      if (!userId) {
        throw new Error('User ID is required');
      }

      // Check if customer
      const customerDoc = await db.collection('customers').doc(userId).get();
      if (customerDoc.exists) {
        return {
          success: true,
          userType: 'customer',
          data: { id: userId, ...customerDoc.data() },
        };
      }

      // Check if courier
      const courierDoc = await db.collection('couriers').doc(userId).get();
      if (courierDoc.exists) {
        return {
          success: true,
          userType: 'courier',
          data: { id: userId, ...courierDoc.data() },
        };
      }

      throw new Error('User profile not found in database');
    } catch (error) {
      throw error;
    }
  }

  // Update Password
  static async updatePassword(userId, newPassword) {
    try {
      const { error } = await supabase.auth.updateUser({
        password: newPassword,
      });

      if (error) throw error;

      return { success: true, message: 'Password updated successfully' };
    } catch (error) {
      throw error;
    }
  }
}

module.exports = AuthService;
