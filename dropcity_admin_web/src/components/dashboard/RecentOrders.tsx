'use client';

import React from 'react';

export default function RecentOrders() {
  const orders = [
    { id: 'ORD001', client: 'John Doe', status: 'delivered', amount: '$45.00' },
    { id: 'ORD002', client: 'Jane Smith', status: 'on_way', amount: '$32.50' },
    { id: 'ORD003', client: 'Bob Johnson', status: 'pending', amount: '$28.75' },
    { id: 'ORD004', client: 'Alice Brown', status: 'delivered', amount: '$55.00' },
  ];

  const statusColor = (status: string) => {
    switch (status) {
      case 'delivered':
        return 'bg-green-500/20 text-green-400';
      case 'on_way':
        return 'bg-blue-500/20 text-blue-400';
      case 'pending':
        return 'bg-yellow-500/20 text-yellow-400';
      default:
        return 'bg-gray-500/20 text-gray-400';
    }
  };

  return (
    <div className="bg-slate-700 border border-slate-600 rounded-lg p-6">
      <h2 className="text-xl font-bold text-white mb-6">Recent Orders</h2>
      <div className="space-y-4">
        {orders.map((order) => (
          <div
            key={order.id}
            className="flex items-center justify-between p-4 bg-slate-600 rounded-lg hover:bg-slate-500 transition-colors"
          >
            <div>
              <p className="text-white font-semibold">{order.id}</p>
              <p className="text-gray-400 text-sm">{order.client}</p>
            </div>
            <div className="flex items-center gap-3">
              <span className={`px-3 py-1 rounded-full text-xs font-medium ${statusColor(order.status)}`}>
                {order.status.replace('_', ' ')}
              </span>
              <p className="text-white font-semibold">{order.amount}</p>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
