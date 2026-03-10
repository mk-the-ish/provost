'use client';

import React from 'react';

interface StatCardProps {
  label: string;
  value: string | number;
  icon: string;
  trend: string;
}

export default function StatCard({ label, value, icon, trend }: StatCardProps) {
  const isPositive = trend.startsWith('+');

  return (
    <div className="bg-slate-700 border border-slate-600 rounded-lg p-6 hover:border-blue-500 transition-colors">
      <div className="flex items-start justify-between">
        <div>
          <p className="text-gray-400 text-sm font-medium">{label}</p>
          <p className="text-white text-3xl font-bold mt-2">{value}</p>
          <p className={`text-sm mt-2 ${isPositive ? 'text-green-400' : 'text-red-400'}`}>
            {trend} from last month
          </p>
        </div>
        <div className="text-4xl">{icon}</div>
      </div>
    </div>
  );
}
