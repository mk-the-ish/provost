require('dotenv').config();
const { createClient } = require('@supabase/supabase-js');

const url = process.env.SUPABASE_URL;
const key = process.env.SUPABASE_ANON_KEY;

console.log('Testing Supabase connectivity...');
console.log('URL:', url);
console.log('Key loaded:', !!key);

const supabase = createClient(url, key);

(async () => {
  try {
    console.log('Attempting to get session...');
    const { data, error } = await supabase.auth.getSession();
    console.log('Session data:', data);
    if (error) console.log('Error:', error);
  } catch (e) {
    console.log('Exception:', e.message);
  }
})();
