const { createClient } = require('@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseAnonKey = process.env.SUPABASE_ANON_KEY;
const supabaseServiceKey = process.env.SUPABASE_SERVICE_KEY;

// Validate required environment variables
if (!supabaseUrl) {
  console.error('❌ SUPABASE_URL not found in environment variables');
}

if (!supabaseAnonKey) {
  console.error('❌ SUPABASE_ANON_KEY not found in environment variables');
}

if (!supabaseServiceKey) {
  console.warn('⚠️  SUPABASE_SERVICE_KEY not found in environment variables');
}


let supabase = null;
if (supabaseUrl && supabaseAnonKey) {
  supabase = createClient(supabaseUrl, supabaseAnonKey);
} else {
  console.warn('⚠️  Supabase credentials incomplete - using placeholder');
  supabase = createClient(supabaseUrl || 'https://placeholder.supabase.co', supabaseAnonKey || 'placeholder-key');
}

// Create admin client for admin operations (uses SERVICE_KEY)
let supabaseAdmin = null;
if (supabaseUrl && supabaseServiceKey) {
  supabaseAdmin = createClient(supabaseUrl, supabaseServiceKey);
}

// Add admin auth helper to main client for consistency
if (supabaseAdmin) {
  supabase.auth.admin = supabaseAdmin.auth.admin;
}

if (supabaseUrl && supabaseAnonKey) {
  console.log('✅ Supabase client initialized');
}

module.exports = { supabase, supabaseAdmin };

