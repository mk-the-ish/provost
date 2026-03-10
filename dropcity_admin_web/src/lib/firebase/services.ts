import { db } from '@/lib/firebase/config';
import { DashboardStats, AnalyticsData } from '@/types';
import {
  collection,
  query,
  where,
  getDocs,
  Timestamp,
  orderBy,
  limit,
} from 'firebase/firestore';

export const getDashboardStats = async (): Promise<DashboardStats> => {
  try {
    const today = new Date();
    today.setHours(0, 0, 0, 0);

    const ordersRef = collection(db, 'orders');

    // Get all orders
    const allOrdersSnap = await getDocs(ordersRef);
    const totalOrders = allOrdersSnap.size;

    // Get active orders
    const activeQuery = query(ordersRef, where('status', 'in', ['pending', 'accepted', 'on_way']));
    const activeSnap = await getDocs(activeQuery);
    const activeOrders = activeSnap.size;

    // Get completed today
    const completedQuery = query(
      ordersRef,
      where('status', '==', 'delivered'),
      where('updatedAt', '>=', Timestamp.fromDate(today))
    );
    const completedSnap = await getDocs(completedQuery);
    const completedToday = completedSnap.size;

    // Calculate revenue
    let totalRevenue = 0;
    allOrdersSnap.forEach((doc) => {
      totalRevenue += doc.data().price || 0;
    });

    // Get active couriers
    const couriersRef = collection(db, 'couriers');
    const activeCouriersQuery = query(couriersRef, where('isActive', '==', true));
    const activeCouriersSnap = await getDocs(activeCouriersQuery);

    return {
      totalOrders,
      activeOrders,
      completedToday,
      totalRevenue,
      averageDeliveryTime: 45, // Placeholder
      activeCouriers: activeCouriersSnap.size,
    };
  } catch (error) {
    console.error('Error fetching dashboard stats:', error);
    return {
      totalOrders: 0,
      activeOrders: 0,
      completedToday: 0,
      totalRevenue: 0,
      averageDeliveryTime: 0,
      activeCouriers: 0,
    };
  }
};

export const getAnalyticsData = async (days: number = 7): Promise<AnalyticsData[]> => {
  try {
    const ordersRef = collection(db, 'orders');
    const startDate = new Date();
    startDate.setDate(startDate.getDate() - days);

    const q = query(
      ordersRef,
      where('createdAt', '>=', Timestamp.fromDate(startDate)),
      orderBy('createdAt', 'desc'),
      limit(days * 50) // Max 50 orders per day
    );

    const snapshot = await getDocs(q);
    const dataMap = new Map<string, AnalyticsData>();

    snapshot.forEach((doc) => {
      const data = doc.data();
      const date = data.createdAt?.toDate?.();
      if (date) {
        const dateStr = date.toISOString().split('T')[0];
        const existing = dataMap.get(dateStr) || {
          date: dateStr,
          orders: 0,
          revenue: 0,
          deliveries: 0,
        };
        existing.orders += 1;
        existing.revenue += data.price || 0;
        if (data.status === 'delivered') existing.deliveries += 1;
        dataMap.set(dateStr, existing);
      }
    });

    return Array.from(dataMap.values()).sort((a, b) =>
      a.date.localeCompare(b.date)
    );
  } catch (error) {
    console.error('Error fetching analytics:', error);
    return [];
  }
};
