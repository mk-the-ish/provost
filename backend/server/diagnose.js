console.log('Starting diagnostic check...');

try {
  console.log('1. Loading express-async-errors...');
  require('express-async-errors');
  console.log('   ✓ OK');
} catch (e) {
  console.error('   ✗ Error:', e.message);
}

try {
  console.log('2. Loading authMiddleware...');
  const authMiddleware = require('./src/middleware/authMiddleware');
  console.log('   ✓ OK - type:', typeof authMiddleware);
} catch (e) {
  console.error('   ✗ Error:', e.message);
}

try {
  console.log('3. Loading auth routes...');
  const authRoutes = require('./src/routes/auth.routes');
  console.log('   ✓ OK');
} catch (e) {
  console.error('   ✗ Error:', e.message);
}

try {
  console.log('4. Loading express app...');
  const app = require('./src/index');
  console.log('   ✓ OK');
} catch (e) {
  console.error('   ✗ Error:', e.message);
  console.error(e.stack);
}

console.log('Diagnostic complete!');
