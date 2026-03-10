export interface User {
  id: string;
  email: string;
  name: string;
  role: 'admin' | 'manager' | 'support';
  createdAt: Date;
}

export interface Order {
  id: string;
  orderId: string;
  clientId: string;
  courierId?: string;
  pickupAddress: string;
  deliveryAddress: string;
  status: 'pending' | 'accepted' | 'on_way' | 'arrived' | 'delivered' | 'cancelled';
  estimatedTime: number;
  actualTime?: number;
  price: number;
  paymentMethod: string;
  createdAt: Date;
  updatedAt: Date;
}

export interface Courier {
  id: string;
  name: string;
  email: string;
  phone: string;
  vehicle: string;
  rating: number;
  completedDeliveries: number;
  isActive: boolean;
  location?: {
    lat: number;
    lng: number;
  };
  createdAt: Date;
}

export interface DashboardStats {
  totalOrders: number;
  activeOrders: number;
  completedToday: number;
  totalRevenue: number;
  averageDeliveryTime: number;
  activeCouriers: number;
}

export interface AnalyticsData {
  date: string;
  orders: number;
  revenue: number;
  deliveries: number;
}
