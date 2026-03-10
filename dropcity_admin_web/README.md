# Dropcity Admin Dashboard

A modern, responsive Next.js 14+ admin dashboard for managing the Dropcity courier delivery application. Built with TypeScript, Tailwind CSS, Firebase, and Recharts for analytics.

## Features

- **Authentication**: Firebase-based admin authentication
- **Dashboard**: Real-time statistics and KPI monitoring
- **Orders Management**: View and manage all delivery orders
- **Courier Management**: Manage courier profiles and assignments
- **User Management**: Manage admin users and permissions
- **Analytics**: Visual insights with charts and trends
- **Responsive Design**: Mobile-friendly interface
- **Dark Theme**: Modern dark-themed UI with Tailwind CSS

## Tech Stack

- **Framework**: Next.js 14 (App Router)
- **Language**: TypeScript
- **Styling**: Tailwind CSS
- **State Management**: Zustand
- **Backend**: Firebase (Auth, Firestore, Storage)
- **Charts**: Recharts
- **Notifications**: React Hot Toast
- **HTTP Client**: Axios

## Project Structure

```
src/
├── app/
│   ├── dashboard/         # Dashboard pages and layout
│   ├── auth/              # Authentication pages
│   ├── layout.tsx         # Root layout
│   ├── page.tsx           # Home redirect
│   └── globals.css        # Global styles
├── components/
│   ├── dashboard/         # Dashboard-specific components
│   │   ├── StatCard.tsx
│   │   ├── OrdersChart.tsx
│   │   └── RecentOrders.tsx
│   └── common/            # Shared components
│       ├── Header.tsx
│       └── Sidebar.tsx
├── lib/
│   ├── firebase/          # Firebase configuration and services
│   │   ├── config.ts
│   │   └── services.ts
│   └── store/             # Zustand stores
│       └── authStore.ts
├── types/
│   └── index.ts           # TypeScript type definitions
└── hooks/
    └── useAuth.ts         # Authentication hook
```

## Setup Instructions

### 1. Install Dependencies

```bash
npm install
```

### 2. Configure Firebase

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Copy your Firebase config
3. Create `.env.local` file from `.env.example`:

```bash
cp .env.example .env.local
```

4. Add your Firebase credentials to `.env.local`

### 3. Enable Firebase Services

In Firebase Console:
- Enable Authentication (Email/Password)
- Enable Firestore Database
- Enable Cloud Storage
- Set up appropriate security rules

### 4. Create Admin User

Use Firebase Console or CLI to create an admin user:
```bash
firebase auth:create --email admin@dropcity.com --password Dropcity@123
```

### 5. Run Development Server

```bash
npm run dev
```

Open [http://localhost:3000](http://localhost:3000) and you'll be redirected to the login page.

**Demo Credentials**:
- Email: `admin@dropcity.com`
- Password: `Dropcity@123`

## Available Scripts

```bash
# Development server
npm run dev

# Build for production
npm run build

# Start production server
npm run start

# Run linter
npm run lint

# Format code
npm run format
```

## Pages & Routes

- `/` - Redirects to dashboard
- `/auth/login` - Admin login page
- `/dashboard` - Main dashboard with KPIs
- `/dashboard/orders` - Orders management (coming soon)
- `/dashboard/couriers` - Couriers management (coming soon)
- `/dashboard/users` - Users management (coming soon)
- `/dashboard/analytics` - Detailed analytics (coming soon)
- `/dashboard/settings` - Settings (coming soon)

## Components

### Dashboard Components

- **StatCard**: Displays KPI statistics with trends
- **OrdersChart**: Line chart showing orders and revenue trends
- **RecentOrders**: List of recent orders with status

### Common Components

- **Header**: Top navigation with user info and logout
- **Sidebar**: Left navigation menu

## API Integration

The dashboard integrates with:
- Firebase Firestore for data storage
- Firebase Authentication for user management
- Backend API (when configured) at `NEXT_PUBLIC_API_URL`

## Firebase Firestore Schema

### Collections

**orders**
```typescript
{
  id: string
  orderId: string
  clientId: string
  courierId?: string
  pickupAddress: string
  deliveryAddress: string
  status: 'pending' | 'accepted' | 'on_way' | 'arrived' | 'delivered' | 'cancelled'
  estimatedTime: number
  actualTime?: number
  price: number
  paymentMethod: string
  createdAt: Timestamp
  updatedAt: Timestamp
}
```

**couriers**
```typescript
{
  id: string
  name: string
  email: string
  phone: string
  vehicle: string
  rating: number
  completedDeliveries: number
  isActive: boolean
  location?: { lat: number, lng: number }
  createdAt: Timestamp
}
```

**admin_users**
```typescript
{
  id: string
  email: string
  name: string
  role: 'admin' | 'manager' | 'support'
  createdAt: Timestamp
}
```

## Environment Variables

```
NEXT_PUBLIC_FIREBASE_API_KEY         # Firebase API Key
NEXT_PUBLIC_FIREBASE_AUTH_DOMAIN     # Firebase Auth Domain
NEXT_PUBLIC_FIREBASE_PROJECT_ID      # Firebase Project ID
NEXT_PUBLIC_FIREBASE_STORAGE_BUCKET  # Firebase Storage Bucket
NEXT_PUBLIC_FIREBASE_MESSAGING_SENDER_ID  # Firebase Sender ID
NEXT_PUBLIC_FIREBASE_APP_ID          # Firebase App ID
NEXT_PUBLIC_API_URL                  # Backend API URL
ADMIN_EMAIL                          # Default admin email
```

## Deployment

### Deploy to Vercel

```bash
vercel deploy
```

### Deploy to Other Platforms

Ensure environment variables are set in your deployment platform's configuration.

## Future Enhancements

- [ ] Orders management with filters and search
- [ ] Courier tracking with real-time map integration
- [ ] Advanced analytics and reports
- [ ] User roles and permissions management
- [ ] Notification system
- [ ] Email notifications integration
- [ ] Mobile app admin dashboard
- [ ] Export reports to PDF/CSV

## Contributing

This is part of the Dropcity project. For guidelines, please refer to the main project documentation.

## License

© 2026 Dropcity. All rights reserved.

## Support

For support, contact the development team or create an issue in the repository.

This project uses [`next/font`](https://nextjs.org/docs/app/building-your-application/optimizing/fonts) to automatically optimize and load [Geist](https://vercel.com/font), a new font family for Vercel.

## Learn More

To learn more about Next.js, take a look at the following resources:

- [Next.js Documentation](https://nextjs.org/docs) - learn about Next.js features and API.
- [Learn Next.js](https://nextjs.org/learn) - an interactive Next.js tutorial.

You can check out [the Next.js GitHub repository](https://github.com/vercel/next.js) - your feedback and contributions are welcome!

## Deploy on Vercel

The easiest way to deploy your Next.js app is to use the [Vercel Platform](https://vercel.com/new?utm_medium=default-template&filter=next.js&utm_source=create-next-app&utm_campaign=create-next-app-readme) from the creators of Next.js.

Check out our [Next.js deployment documentation](https://nextjs.org/docs/app/building-your-application/deploying) for more details.
