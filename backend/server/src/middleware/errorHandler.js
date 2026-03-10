const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);

  // Supabase Auth Errors
  if (
    err.message?.includes('Invalid login credentials') ||
    err.message?.includes('invalid_credentials')
  ) {
    return res.status(401).json({
      success: false,
      message: 'Invalid email or password',
      error: 'AUTH_ERROR',
    });
  }

  if (
    err.message?.includes('User already registered') ||
    err.message?.includes('already exists')
  ) {
    return res.status(409).json({
      success: false,
      message: 'Email already registered. Please use a different email or login.',
      error: 'USER_EXISTS',
    });
  }

  if (err.message?.includes('Email not confirmed')) {
    return res.status(403).json({
      success: false,
      message: 'Please confirm your email before logging in',
      error: 'EMAIL_NOT_CONFIRMED',
    });
  }

  if (err.message?.includes('Database connection not initialized')) {
    return res.status(500).json({
      success: false,
      message: 'Database connection failed. Please check server configuration.',
      error: 'DB_CONNECTION_ERROR',
    });
  }

  if (err.message?.includes('User profile not found')) {
    return res.status(404).json({
      success: false,
      message: 'User profile not found. Please complete registration first.',
      error: 'USER_PROFILE_NOT_FOUND',
    });
  }

  // JWT Errors
  if (err.name === 'JsonWebTokenError') {
    return res.status(401).json({
      success: false,
      message: 'Invalid token',
      error: 'INVALID_TOKEN',
    });
  }

  if (err.name === 'TokenExpiredError') {
    return res.status(401).json({
      success: false,
      message: 'Token expired. Please login again.',
      error: 'TOKEN_EXPIRED',
    });
  }

  // Validation Errors
  if (err.validationErrors) {
    return res.status(400).json({
      success: false,
      message: 'Validation failed',
      errors: err.validationErrors,
    });
  }

  // Missing required fields
  if (err.message?.includes('Missing required')) {
    return res.status(400).json({
      success: false,
      message: err.message,
      error: 'VALIDATION_ERROR',
    });
  }

  // Default Error
  res.status(err.statusCode || 500).json({
    success: false,
    message: err.message || 'Internal server error',
    error: 'INTERNAL_ERROR',
  });
};

module.exports = { errorHandler };
