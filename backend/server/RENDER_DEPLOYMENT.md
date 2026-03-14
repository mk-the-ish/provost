# DropCity Backend Server
# Deployment Guide for Render

## Quick Start on Render

### Step 1: Prepare Your Repository

```bash
# Ensure .env.example exists with all required variables
# Ensure package.json has proper scripts:
# - "start": "node src/index.js"
# - "dev": "nodemon src/index.js"

# Ensure Procfile exists with:
# web: npm start
```

### Step 2: Create Render Service

1. Go to [render.com](https://render.com)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Select the `backend/server` directory as the root
5. Configure:
   - **Name**: dropcity-backend
   - **Environment**: Node
   - **Build Command**: `npm install`
   - **Start Command**: `npm start`
   - **Node Version**: 18 (or latest)

### Step 3: Set Environment Variables

In Render Dashboard → Settings → Environment:

```
PORT=5000
NODE_ENV=production

FIREBASE_PROJECT_ID=dropcity-aadac
FIREBASE_PRIVATE_KEY=your_actual_private_key
FIREBASE_CLIENT_EMAIL=your_actual_email@appspot.gserviceaccount.com

SUPABASE_URL=https://jchieiiunnvjawmdsgqe.supabase.co
SUPABASE_ANON_KEY=your_actual_anon_key
SUPABASE_SERVICE_KEY=your_actual_service_key

JWT_SECRET=your_long_random_secret_min_32_chars
JWT_EXPIRE=7d

GOOGLE_MAPS_API_KEY=your_google_maps_api_key

CORS_ORIGIN=https://your-frontend-domain.com

LOG_LEVEL=info

SOCKET_IO_CORS_ORIGIN=https://your-frontend-domain.com
```

### Step 4: Deploy

1. Click "Deploy"
2. Render will:
   - Clone your repo
   - Install dependencies
   - Start the server
   - Assign a URL (e.g., `https://dropcity-backend.onrender.com`)

### Step 5: Verify Deployment

```bash
# Check health endpoint
curl https://dropcity-backend.onrender.com/health

# Response:
# {"status":"ok","timestamp":"2026-03-14T10:30:00.000Z"}
```

---

## Important Notes

### Cold Starts
- Free tier: Service goes to sleep after 15 minutes of inactivity
- Paid tier: Always on, better for production
- First request after sleep takes 30-60 seconds

### Database Connections
- Render doesn't provide a database; using Supabase + Firestore
- No local SQLite persistence (stateless)
- Offline GPS queue stored in device SQLite, synced to cloud

### Scaling
- Free tier: 0.5 CPU, 512MB RAM - suitable for testing
- Standard tier: 1 CPU, 1GB RAM - suitable for production with ~100 concurrent users
- Pro tier: Dedicated resources for high traffic

### Environment Variables
- Keep `FIREBASE_PRIVATE_KEY` and `SUPABASE_SERVICE_KEY` secure
- Private key format: Copy exact format from Firebase console (with `\n` for newlines)
- Never commit `.env` to Git

---

## Firebase Private Key Setup

The Firebase private key must be properly formatted:

```json
{
  "type": "service_account",
  "project_id": "dropcity-aadac",
  "private_key_id": "...",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIB...\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-...@appspot.gserviceaccount.com",
  ...
}
```

For Render, use the full multi-line key with `\n` preserved:

```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQE...
...
-----END PRIVATE KEY-----
```

Or use single line with escaped newlines:
```
-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQE...\n-----END PRIVATE KEY-----\n
```

---

## Monitoring & Logs

In Render Dashboard:

1. **Logs**: Real-time server logs
2. **Metrics**: CPU, Memory, Network usage
3. **Events**: Deployments, crashes, scaling

### Enable Debug Logging

Set `LOG_LEVEL=debug` in environment to see:
- All API requests/responses
- Database queries
- Socket.io connections
- Error stack traces

---

## API Endpoints After Deployment

Replace `https://dropcity-backend.onrender.com` with your actual Render URL:

```bash
# Health Check
GET https://dropcity-backend.onrender.com/health

# Register Courier
POST https://dropcity-backend.onrender.com/api/auth/register/courier
Content-Type: application/json

{
  "email": "courier@example.com",
  "password": "Test123!",
  "fullName": "John Courier",
  "phoneNumber": "+1234567890",
  "licenseNumber": "DL123456",
  "vehicleType": "motorcycle"
}

# Declare Route
POST https://dropcity-backend.onrender.com/api/routes/declare
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "startLat": 40.7128,
  "startLng": -74.0060,
  "endLat": 40.7580,
  "endLng": -73.9855,
  "encodedPolyline": "40.7128,-74.0060|40.7138,-74.0058|...",
  "distance": "12.5",
  "estimatedDuration": "45 mins"
}
```

---

## Troubleshooting

### Service Won't Start

Check logs for:
- `Cannot find module` → Missing dependency in package.json
- `PORT already in use` → Use `process.env.PORT`
- `Cannot read property of undefined` → Check environment variables

### Database Connection Errors

- Verify `SUPABASE_URL` and keys are correct
- Check Supabase project is not paused
- Verify PostgreSQL extensions (PostGIS) are enabled

### CORS Errors

- Set `CORS_ORIGIN` to your frontend URL
- Update Socket.io `SOCKET_IO_CORS_ORIGIN`

### High Memory Usage

- Check for memory leaks in loops
- Restart service (Render → Settings → Restart)
- Upgrade to paid tier if needed

---

## Next Steps

1. Push to GitHub
2. Connect GitHub to Render
3. Configure environment variables
4. Deploy and test
5. Update frontend with API URL
6. Monitor logs and metrics

**Deployment Time**: ~2-3 minutes  
**Estimated Cost**: Free tier to $12/month Pro tier

