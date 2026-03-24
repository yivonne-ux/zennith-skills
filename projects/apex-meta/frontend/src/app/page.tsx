'use client'

import { useEffect, useState } from 'react'

interface Brand {
  id: string
  name: string
  slug: string
  meta_ad_account_id: string | null
  roas_target: number
  onboarding_complete: boolean
}

interface HealthStatus {
  status: string
  version: string
  database: string
  redis: string
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:8000/api/v1'

export default function Dashboard() {
  const [health, setHealth] = useState<HealthStatus | null>(null)
  const [brands, setBrands] = useState<Brand[]>([])
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    async function fetchData() {
      try {
        const [healthRes, brandsRes] = await Promise.all([
          fetch(`${API_BASE}/health`),
          fetch(`${API_BASE}/brands/`),
        ])
        if (healthRes.ok) setHealth(await healthRes.json())
        if (brandsRes.ok) setBrands(await brandsRes.json())
      } catch (e) {
        console.error('Failed to fetch:', e)
      } finally {
        setLoading(false)
      }
    }
    fetchData()
  }, [])

  return (
    <main className="min-h-screen p-8 max-w-7xl mx-auto">
      <header className="mb-8">
        <h1 className="text-3xl font-bold tracking-tight">Apex Meta</h1>
        <p className="text-gray-500 mt-1">God Mode Meta Ads Intelligence</p>
      </header>

      {/* System Health */}
      <section className="card mb-6">
        <h2 className="text-lg font-semibold mb-3">System Health</h2>
        {loading ? (
          <p className="text-gray-400">Loading...</p>
        ) : health ? (
          <div className="grid grid-cols-4 gap-4">
            <StatusBadge label="Status" value={health.status} />
            <StatusBadge label="Version" value={health.version} />
            <StatusBadge label="Database" value={health.database} />
            <StatusBadge label="Redis" value={health.redis} />
          </div>
        ) : (
          <p className="text-red-500">Backend unreachable</p>
        )}
      </section>

      {/* Brands */}
      <section className="card">
        <h2 className="text-lg font-semibold mb-3">Brands</h2>
        {brands.length === 0 ? (
          <p className="text-gray-400">
            No brands configured. POST to /api/v1/brands/ to add one.
          </p>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {brands.map((brand) => (
              <div
                key={brand.id}
                className="border rounded-lg p-4 hover:shadow-md transition-shadow"
              >
                <h3 className="font-semibold text-lg">{brand.name}</h3>
                <p className="text-sm text-gray-500">{brand.slug}</p>
                <div className="mt-2 flex gap-2">
                  {brand.meta_ad_account_id ? (
                    <span className="badge-green">Meta Connected</span>
                  ) : (
                    <span className="badge-orange">No Meta Account</span>
                  )}
                  <span className="text-xs text-gray-400">
                    ROAS Target: {brand.roas_target}x
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </section>
    </main>
  )
}

function StatusBadge({ label, value }: { label: string; value: string }) {
  const isGood = value === 'healthy' || value === 'connected'
  return (
    <div className="text-center">
      <p className="text-xs text-gray-500 uppercase tracking-wider">{label}</p>
      <p className={`text-sm font-medium ${isGood ? 'text-green-600' : 'text-orange-600'}`}>
        {value}
      </p>
    </div>
  )
}
