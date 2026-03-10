#!/usr/bin/env node

/**
 * DropCity API Testing Suite
 * Tests all endpoints to verify backend functionality
 */

const http = require('http');
const https = require('https');

const BASE_URL = 'http://localhost:5000';
const TIMEOUT = 5000;

let testResults = {
  passed: 0,
  failed: 0,
  tests: []
};

// Test data
let authTokens = {
  customer: null,
  courier: null,
  customerId: null,
  courierId: null,
  orderId: null
};

/**
 * Make HTTP request
 */
function makeRequest(method, path, body = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(BASE_URL + path);
    
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: TIMEOUT
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let data = '';
      
      res.on('data', chunk => {
        data += chunk;
      });

      res.on('end', () => {
        try {
          const parsed = data ? JSON.parse(data) : {};
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: parsed
          });
        } catch (e) {
          resolve({
            status: res.statusCode,
            headers: res.headers,
            body: data
          });
        }
      });
    });

    req.on('error', reject);
    req.on('timeout', () => {
      req.destroy();
      reject(new Error('Request timeout'));
    });

    if (body) {
      req.write(JSON.stringify(body));
    }
    
    req.end();
  });
}

/**
 * Log test result
 */
function logTest(name, passed, details = '') {
  testResults.tests.push({ name, passed, details });
  if (passed) {
    testResults.passed++;
    console.log(`✅ ${name}`);
    if (details) console.log(`   ${details}`);
  } else {
    testResults.failed++;
    console.log(`❌ ${name}`);
    if (details) console.log(`   ${details}`);
  }
}

/**
 * Assert status code
 */
function assertStatus(response, expected, testName, successDetails = '') {
  const passed = response.status === expected;
  logTest(testName, passed, `Expected ${expected}, got ${response.status}${successDetails ? '. ' + successDetails : ''}`);
  return passed;
}

/**
 * Run all tests
 */
async function runTests() {
  console.log('\n🧪 DropCity API Testing Suite\n');
  console.log('=' .repeat(50));

  try {
    // ===== HEALTH CHECK =====
    console.log('\n📋 Health Check');
    const health = await makeRequest('GET', '/health');
    assertStatus(health, 200, 'Health endpoint');

    // ===== AUTHENTICATION TESTS =====
    console.log('\n🔐 Authentication');

    // Register Customer
    const customerReg = await makeRequest('POST', '/auth/register-customer', {
      email: `customer-${Date.now()}@test.com`,
      password: 'password123',
      name: 'Test Customer',
      phone: '+1234567890'
    });
    authTokens.customerId = customerReg.body.userId;
    authTokens.customer = customerReg.body.token;
    assertStatus(customerReg, 201, 'Register Customer', `User ID: ${customerReg.body.userId?.substring(0, 8)}`);

    // Register Courier
    const courierReg = await makeRequest('POST', '/auth/register-courier', {
      email: `courier-${Date.now()}@test.com`,
      password: 'password123',
      name: 'Test Courier',
      phone: '+9876543210',
      vehicleType: 'bike',
      vehicleNumber: 'TEST-1234'
    });
    authTokens.courierId = courierReg.body.userId;
    authTokens.courier = courierReg.body.token;
    assertStatus(courierReg, 201, 'Register Courier', `User ID: ${courierReg.body.userId?.substring(0, 8)}`);

    // Login Customer
    const customerLogin = await makeRequest('POST', '/auth/login', {
      email: customerReg.body.email,
      password: 'password123'
    });
    if (customerLogin.status === 200) {
      authTokens.customer = customerLogin.body.token;
    }
    assertStatus(customerLogin, 200, 'Login Customer');

    // Login Courier
    const courierLogin = await makeRequest('POST', '/auth/login', {
      email: courierReg.body.email,
      password: 'password123'
    });
    if (courierLogin.status === 200) {
      authTokens.courier = courierLogin.body.token;
    }
    assertStatus(courierLogin, 200, 'Login Courier');

    // ===== ORDER TESTS =====
    console.log('\n📦 Orders');

    // Create Order
    const orderCreate = await makeRequest('POST', '/orders/create', {
      pickupAddress: '123 Main St, New York',
      deliveryAddress: '456 Park Ave, New York',
      description: 'Test package',
      weight: 2.5,
      estimatedDistance: 5.0
    }, authTokens.customer);
    authTokens.orderId = orderCreate.body.order?.id;
    assertStatus(orderCreate, 201, 'Create Order', `Order ID: ${authTokens.orderId?.substring(0, 8)}`);

    // Get Orders List
    const ordersList = await makeRequest('GET', '/orders/list', null, authTokens.customer);
    assertStatus(ordersList, 200, 'Get Orders List', `Found ${ordersList.body.orders?.length || 0} orders`);

    // Get Order Details
    if (authTokens.orderId) {
      const orderDetails = await makeRequest('GET', `/orders/${authTokens.orderId}`, null, authTokens.customer);
      assertStatus(orderDetails, 200, 'Get Order Details');
    }

    // ===== MATCHING TESTS =====
    console.log('\n🎯 Courier Matching');

    // Find Couriers
    const findCouriers = await makeRequest('GET', '/matching/find-couriers?latitude=40.7128&longitude=-74.0060&maxDistance=10', null, authTokens.customer);
    assertStatus(findCouriers, 200, 'Find Available Couriers', `Found ${findCouriers.body.couriers?.length || 0} couriers`);

    // Match Order with Courier
    if (authTokens.orderId && authTokens.courierId) {
      const matchOrder = await makeRequest('POST', '/matching/match-order', {
        orderId: authTokens.orderId,
        courierId: authTokens.courierId
      }, authTokens.customer);
      assertStatus(matchOrder, 200, 'Match Order with Courier');
    }

    // ===== TRACKING TESTS =====
    console.log('\n📍 Tracking');

    // Update Location
    const updateLocation = await makeRequest('POST', '/tracking/update-location', {
      latitude: 40.7128,
      longitude: -74.0060,
      altitude: 0,
      accuracy: 5
    }, authTokens.courier);
    assertStatus(updateLocation, 200, 'Update Location');

    // Get Live Tracking
    if (authTokens.orderId) {
      const liveTracking = await makeRequest('GET', `/tracking/${authTokens.orderId}/live`, null, authTokens.customer);
      assertStatus(liveTracking, 200, 'Get Live Tracking');
    }

    // Get Delivery Events
    if (authTokens.orderId) {
      const deliveryEvents = await makeRequest('GET', `/tracking/${authTokens.orderId}/events`, null, authTokens.customer);
      assertStatus(deliveryEvents, 200, 'Get Delivery Events', `Found ${deliveryEvents.body.events?.length || 0} events`);
    }

    // ===== COURIER TESTS =====
    console.log('\n👤 Courier Profile');

    // Get Courier Profile
    const courierProfile = await makeRequest('GET', '/couriers/profile', null, authTokens.courier);
    assertStatus(courierProfile, 200, 'Get Courier Profile');

    // Update Courier Status
    const updateStatus = await makeRequest('PUT', '/couriers/status', {
      isOnline: true
    }, authTokens.courier);
    assertStatus(updateStatus, 200, 'Update Courier Status');

    // Get Courier Orders
    const courierOrders = await makeRequest('GET', '/couriers/orders', null, authTokens.courier);
    assertStatus(courierOrders, 200, 'Get Courier Orders', `Found ${courierOrders.body.orders?.length || 0} orders`);

    // ===== RATING TESTS =====
    console.log('\n⭐ Ratings');

    // Rate Order
    if (authTokens.orderId) {
      const rateOrder = await makeRequest('POST', `/orders/${authTokens.orderId}/rate`, {
        rating: 5,
        feedback: 'Great service!'
      }, authTokens.customer);
      assertStatus(rateOrder, 200, 'Rate Order');
    }

  } catch (error) {
    console.error('\n❌ Fatal error:', error.message);
    process.exit(1);
  }

  // ===== RESULTS =====
  console.log('\n' + '='.repeat(50));
  console.log('\n📊 Test Results\n');
  console.log(`✅ Passed: ${testResults.passed}`);
  console.log(`❌ Failed: ${testResults.failed}`);
  console.log(`📈 Total:  ${testResults.tests.length}`);
  console.log(`📊 Success Rate: ${((testResults.passed / testResults.tests.length) * 100).toFixed(1)}%\n`);

  if (testResults.failed === 0) {
    console.log('🎉 All tests passed! The API is ready for frontend integration.\n');
    process.exit(0);
  } else {
    console.log(`⚠️  ${testResults.failed} test(s) failed. Please review the errors above.\n`);
    process.exit(1);
  }
}

// Run tests
runTests();
