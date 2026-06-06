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
      <header className="flex items-center gap-3 border-b border-border/60 bg-[#1e3a4a] px-4 py-3 no-print shadow-sm">
        <div className="flex items-center gap-2.5">
          <div className="flex h-9 w-9 items-center justify-center rounded-lg bg-white/10 ring-1 ring-white/20">
            <Layers className="h-5 w-5 text-white" />
          </div>
          <div>
            <span className="text-base font-bold text-white leading-tight block">Декоратор</span>
            <span className="text-[10px] text-white/60 leading-tight block">ООО «АКЦЕНТ»</span>
          </div>
        </div>
        <span className="ml-auto text-[11px] text-white/50 hidden sm:block">Штукатурка · Декор · Отделка</span>
      </header>

      {/* Content */}
      <main className="flex-1 overflow-auto">
        <Outlet />
      </main>

      {/* Bottom navigation */}
      <nav className="border-t border-border bg-card shadow-[0_-1px_8px_rgba(0,0,0,0.06)] no-print">
        <div className="flex">
          {navItems.map(({ to, label, icon: Icon, exact }) => {
            const active = exact ? location.pathname === to : location.pathname.startsWith(to)
            return (
              <NavLink
                key={to}
                to={to}
                className={cn(
                  'flex flex-1 flex-col items-center gap-0.5 py-2.5 px-1 text-xs transition-all relative',
                  active ? 'text-primary' : 'text-muted-foreground hover:text-foreground'
                )}
              >
                {active && (
                  <span className="absolute top-0 left-1/2 -translate-x-1/2 w-8 h-0.5 rounded-full bg-primary" />
                )}
                <div className={cn(
                  'rounded-lg p-1 transition-colors',
                  active ? 'bg-primary/10' : ''
                )}>
                  <Icon className="h-5 w-5" />
                </div>
                <span className={cn('font-medium', active ? 'text-primary' : '')}>{label}</span>
              </NavLink>
            )
          })}
        </div>
      </nav>
    </div>
  )
}
