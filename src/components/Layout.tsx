import { NavLink, Outlet, useLocation } from 'react-router-dom'
import { Calculator, FileText, Sparkles, Settings, Layers } from 'lucide-react'
import { cn } from '@/lib/utils'

const navItems = [
  { to: '/', label: 'Калькулятор', icon: Calculator, exact: true },
  { to: '/invoices', label: 'Накладные', icon: FileText },
  { to: '/recommendations', label: 'Подбор', icon: Sparkles },
  { to: '/settings', label: 'Настройки', icon: Settings },
]

export function Layout() {
  const location = useLocation()

  return (
    <div className="flex h-dvh flex-col bg-background">
      {/* Header */}
      <header className="flex items-center gap-3 border-b border-border bg-card px-4 py-3 no-print">
        <div className="flex items-center gap-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-primary">
            <Layers className="h-5 w-5 text-primary-foreground" />
          </div>
          <span className="text-lg font-bold text-foreground">Декоратор</span>
        </div>
        <span className="ml-auto text-xs text-muted-foreground">Штукатурка и отделка</span>
      </header>

      {/* Content */}
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>

      {/* Bottom navigation */}
      <nav className="border-t border-border bg-card no-print">
        <div className="flex">
          {navItems.map(({ to, label, icon: Icon, exact }) => {
            const active = exact ? location.pathname === to : location.pathname.startsWith(to)
            return (
              <NavLink
                key={to}
                to={to}
                className={cn(
                  'flex flex-1 flex-col items-center gap-0.5 py-2 px-1 text-xs transition-colors',
                  active
                    ? 'text-primary'
                    : 'text-muted-foreground hover:text-foreground'
                )}
              >
                <Icon className={cn('h-5 w-5', active && 'fill-primary/10')} />
                <span>{label}</span>
              </NavLink>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
