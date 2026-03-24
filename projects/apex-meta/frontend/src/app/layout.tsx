import type { Metadata } from 'next'
import './globals.css'

export const metadata: Metadata = {
  title: 'Apex Meta — God Mode Meta Ads',
  description: 'Autonomous Multi-Brand Meta Ads Intelligence Platform',
}

export default function RootLayout({
  children,
}: {
  children: React.ReactNode
}) {
  return (
    <html lang="en">
      <body className="antialiased">{children}</body>
    </html>
  )
}
