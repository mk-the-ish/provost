'use client';

import React, { useEffect, useState } from 'react';
import { getDashboardStats, getAnalyticsData } from '@/lib/firebase/services';
import { DashboardStats, AnalyticsData } from '@/types';
import StatCard from '@/components/dashboard/StatCard';
import OrdersChart from '@/components/dashboard/OrdersChart';
import RecentOrders from '@/components/dashboard/RecentOrders';
import toast from 'react-hot-toast';

export default function DashboardPage() {
  const [stats, setStats] = useState<DashboardStats | null>(null);
  const [analytics, setAnalytics] = useState<AnalyticsData[]>([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const fetchData = async () => {
      try {
        const [statsData, analyticsData] = await Promise.all([
          getDashboardStats(),
          getAnalyticsData(7),
        ]);
        setStats(statsData);
        setAnalytics(analyticsData);
      } catch (error) {
        console.error('Error fetching data:', error);
        toast.error('Failed to load dashboard data');
      } finally {
        setLoading(false);
      }
    };

    fetchData();
  }, []);

  if (loading) {
    return (
      <div className="flex items-center justify-center h-screen">
        <div className="text-center">
          <div className="w-12 h-12 border-4 border-blue-500 border-t-transparent rounded-full animate-spin mx-auto"></div>
          <p className="mt-4 text-gray-400">Loading dashboard...</p>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-8">
      {/* Page Header */}
      <div>
        <h1 className="text-3xl font-bold text-white">Dashboard</h1>
        <p className="text-gray-400 mt-2">Welcome to Dropcity Admin Panel</p>
      </div>

      {/* Stats Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        <StatCard
          label="Total Orders"
          value={stats?.totalOrders || 0}
          icon="📦"
          trend="+12%"
        />
        <StatCard
          label="Active Orders"
          value={stats?.activeOrders || 0}
          icon="🚚"
          trend="+5%"
        />
        <StatCard
          label="Completed Today"
          value={stats?.completedToday || 0}
          icon="✅"
          trend="+8%"
        />
        <StatCard
          label="Total Revenue"
          value={`$${(stats?.totalRevenue || 0).toFixed(2)}`}
          icon="💰"
          trend="+15%"
        />
        <StatCard
          label="Active Couriers"
          value={stats?.activeCouriers || 0}
          icon="👤"
          trend="+3%"
        />
        <StatCard
          label="Avg. Delivery Time"
          value={`${stats?.averageDeliveryTime || 0}m`}
          icon="⏱️"
          trend="-2%"
        />
      </div>

      {/* Charts and Orders */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        <div className="lg:col-span-2">
          <OrdersChart data={analytics} />
        </div>
        <div>
          <RecentOrders />
        </div>
      </div>
    </div>
  );
}
