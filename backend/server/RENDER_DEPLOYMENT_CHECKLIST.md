# Render Deployment Checklist for DropCity Backend

## Pre-Deployment ✅

### Code Preparation
- [ ] All code committed to GitHub
- [ ] No hardcoded secrets in code
- [ ] `package.json` has correct `start` script
- [ ] `.env.example` has all required variables
- [ ] `Procfile` exists and is correct
- [ ] `src/index.js` uses `process.env.PORT`

### Repository Setup
- [ ] GitHub account created
- [ ] Repository is public (or add Render as collaborator)
- [ ] `.gitignore` excludes `.env` and `node_modules/`
- [ ] Main branch is up to date

### External Services
- [ ] Firebase service account key obtained
- [ ] Supabase keys obtained (Service Key + Anon Key)
- [ ] Google Maps API key created
- [ ] JWT secret generated (min 32 characters)

---

## Render Deployment Steps 🚀

### Step 1: Connect GitHub
1. Go to [render.com](https://render.com)
2. Sign up / Login
3. Click "New +" → "Web Service"
4. Select "Connect a repository"
5. Authorize Render to access GitHub
6. Select `dropcity` repository

### Step 2: Configure Service
1. **Name**: `dropcity-backend` (or preferred name)
2. **Environment**: Node
3. **Build Command**: `npm install`
4. **Start Command**: `npm start`
5. **Node Version**: 18 (latest LTS)

### Step 3: Set Root Directory
- Set to: `backend/server`
- This tells Render where the backend code is

### Step 4: Add Environment Variables
Copy each from `.env.example`:

```
PORT=5000
NODE_ENV=production
FIREBASE_PROJECT_ID=dropcity-aadac
FIREBASE_PRIVATE_KEY=<paste full key with \n>
FIREBASE_CLIENT_EMAIL=<your service account email>
SUPABASE_URL=https://jchieiiunnvjawmdsgqe.supabase.co
SUPABASE_ANON_KEY=<your anon key>
SUPABASE_SERVICE_KEY=<your service key>
JWT_SECRET=<generate 32+ char random string>
JWT_EXPIRE=7d
GOOGLE_MAPS_API_KEY=<your api key>
CORS_ORIGIN=https://your-frontend-url.com
LOG_LEVEL=info
SOCKET_IO_CORS_ORIGIN=https://your-frontend-url.com
```

### Step 5: Choose Plan
- **Free Tier**: $0/month, spins down after 15 min inactivity
- **Standard Tier**: $7/month, good for development
- **Pro Tier**: $12+/month, production-ready with dedicated resources

**Recommendation**: Start with Free, upgrade to Standard after testing

### Step 6: Deploy
1. Click "Create Web Service"
2. Render will start deployment
3. Watch logs for progress
4. Service will be ready in 2-3 minutes

---

## Post-Deployment ✅

### Verify Deployment
```bash
# Test health endpoint
curl https://dropcity-backend.onrender.com/health

# Expected response:
# {"status":"ok","timestamp":"..."}
```

### Update Flutter App
1. In courier app, update API base URL:
   ```dart
   const String API_URL = 'https://dropcity-backend.onrender.com';
   ```

2. Update `lib/utils/api_provider.dart` or similar

### Test API Endpoints
```bash
# Test authentication
curl -X POST https://dropcity-backend.onrender.com/api/auth/register/courier \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "Test123!",
    "fullName": "Test User",
    "phoneNumber": "+1234567890",
    "licenseNumber": "TEST123",
    "vehicleType": "motorcycle"
  }'
```

### Monitor Logs
1. Render Dashboard → Your Service → "Logs"
2. Watch for errors or issues
3. Check startup messages

### Set Up Auto-Deploy
Render automatically deploys on every push to main branch:
- No manual redeploy needed
- Logs show deployment progress
- Previous versions can be rolled back

---

## Troubleshooting 🔧

### Build Failed
**Check logs for**:
- `npm ERR! code ERESOLVE` → Dependency conflict
  - Solution: Delete `package-lock.json`, push again
- `Cannot find module` → Missing dependency
  - Solution: Run `npm install` locally, push `package-lock.json`

### Service Won't Start
**Check for**:
- Missing environment variables → Add in Render Dashboard
- Wrong root directory → Verify `backend/server` is selected
- Port conflicts → Ensure code uses `process.env.PORT`

### CORS Errors
- Update `CORS_ORIGIN` in environment variables
- Restart service (Settings → Restart)

### Database Connection Errors
- Verify all Supabase/Firebase keys are correct
- Check Supabase project isn't paused
- Test connection locally first

### High Memory Usage
- Check for memory leaks in Socket.io
- Review logs for repeated connections
- Restart service or upgrade plan

---

## Important Configuration

### Environment Variables Format

**For multi-line keys** (Firebase Private Key):
```
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQE...
...rest of key...
-----END PRIVATE KEY-----
```

**Or single-line** (copy-paste with \n):
```
-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQE...\n-----END PRIVATE KEY-----\n
```

### CORS Configuration
- For Flutter app: Use your app's domain or `*` (development only)
- For web app: Use exact domain (e.g., `https://app.dropcity.com`)
- Update when deploying frontend

### Database Migrations
Database schema already created in Supabase:
- Run migrations in Supabase SQL Editor (one time)
- Backend reads from Supabase directly
- No need to run migrations in Render

---

## Security Checklist 🔒

- [ ] Never commit `.env` file
- [ ] Rotate `JWT_SECRET` every 6 months
- [ ] Rotate Firebase/Supabase keys if compromised
- [ ] Enable Supabase RLS policies (row-level security)
- [ ] Use HTTPS for all requests
- [ ] Set `NODE_ENV=production` in Render
- [ ] Monitor logs for suspicious activity
- [ ] Keep dependencies updated

---

## Monitoring & Maintenance

### Daily Checks
- [ ] Backend health endpoint responds
- [ ] No error spikes in logs
- [ ] Database connections stable

### Weekly Checks
- [ ] Review API performance metrics
- [ ] Check for unhandled errors
- [ ] Monitor authentication failures

### Monthly Checks
- [ ] Update dependencies: `npm update`
- [ ] Review security vulnerabilities
- [ ] Backup database (Supabase)
- [ ] Verify logs and metrics

---

## Useful Links

- **Render Dashboard**: https://dashboard.render.com
- **Service Logs**: https://dashboard.render.com/services/dropcity-backend
- **Render Docs**: https://render.com/docs
- **Firebase Console**: https://console.firebase.google.com
- **Supabase Dashboard**: https://app.supabase.com

---

## Support & Help

**If deployment fails:**
1. Check Render logs for specific error
2. Verify all environment variables are set
3. Test locally: `npm start`
4. Check GitHub issues or Render support

**Expected Deployment Time**: 2-3 minutes  
**After First Deploy**: ~30 seconds for subsequent pushes  
**Free Tier Spin-Down**: After 15 minutes of inactivity (can take 30-60s to wake up)

---

**Status**: ✅ Ready for Deployment  
**Last Updated**: March 14, 2026  
**Backend Version**: 1.0.0
