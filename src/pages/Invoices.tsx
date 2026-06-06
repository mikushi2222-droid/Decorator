import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency, generateInvoiceNumber } from '@/lib/utils'
import { format } from 'date-fns'
import { ru } from 'date-fns/locale'
import { Card, CardContent } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { Plus, Search, FileText } from 'lucide-react'
import { Input } from '@/components/ui/input'
import type { Invoice } from '@/types'
import { InvoiceForm } from '@/components/InvoiceForm'
import { InvoiceView } from '@/components/InvoiceView'

const STATUS_LABELS: Record<string, string> = {
  draft: 'Черновик',
  sent: 'Выставлена',
  paid: 'Оплачена',
}

const STATUS_VARIANTS: Record<string, 'outline' | 'warning' | 'success'> = {
  draft: 'outline',
  sent: 'warning',
  paid: 'success',
}

export function InvoicesPage() {
  const invoices = useLiveQuery(
    () => db.invoices.orderBy('createdAt').reverse().toArray(),
    []
  )

  const [search, setSearch] = useState('')
  const [view, setView] = useState<'list' | 'create' | 'detail'>('list')
  const [selected, setSelected] = useState<Invoice | null>(null)

  const filtered = (invoices || []).filter(
    (inv) =>
      inv.number.toLowerCase().includes(search.toLowerCase()) ||
      inv.clientName.toLowerCase().includes(search.toLowerCase())
  )

  const handleCreate = async (data: Omit<Invoice, 'id' | 'number' | 'createdAt'>) => {
    // Берём максимальный существующий порядковый номер (не count),
    // чтобы удалённые накладные не вызывали дублирование номеров.
    const last = await db.invoices.orderBy('number').last()
    const lastNum = last ? parseInt(last.number.split('-')[2] ?? '0', 10) : 0
    const number = generateInvoiceNumber(isNaN(lastNum) ? 0 : lastNum)
    await db.invoices.add({
      ...data,
      number,
      createdAt: new Date(),
    })
    setView('list')
  }

  const handleUpdateStatus = async (id: number, status: Invoice['status']) => {
    await db.invoices.update(id, { status })
    if (selected?.id === id) setSelected((prev) => prev ? { ...prev, status } : null)
  }

  const handleDelete = async (id: number) => {
    if (!confirm('Удалить накладную?')) return
    await db.invoices.delete(id)
    setView('list')
    setSelected(null)
  }

  if (view === 'create') {
    return <InvoiceForm onSave={handleCreate} onCancel={() => setView('list')} />
  }

  if (view === 'detail' && selected) {
    return (
      <InvoiceView
        invoice={selected}
        onBack={() => setView('list')}
        onUpdateStatus={(s) => handleUpdateStatus(selected.id!, s)}
        onDelete={() => handleDelete(selected.id!)}
      />
    )
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <FileText className="h-5 w-5 text-primary" />
          Накладные
        </h1>
        <Button size="sm" onClick={() => setView('create')}>
          <Plus className="h-4 w-4" /> Создать
        </Button>
      </div>

      <div className="relative">
        <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
        <Input
          className="pl-9"
          placeholder="Поиск по номеру или клиенту..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {filtered.length === 0 ? (
        <div className="py-16 text-center text-muted-foreground">
          <FileText className="mx-auto h-10 w-10 opacity-30 mb-3" />
          <p className="text-sm">
            {search ? 'Ничего не найдено' : 'Накладных пока нет.\nНажмите «Создать» для начала.'}
          </p>
        </div>
      ) : (
        <div className="space-y-2">
          {filtered.map((inv) => (
            <Card
              key={inv.id}
              className="cursor-pointer hover:border-primary/40 transition-colors"
              onClick={() => { setSelected(inv); setView('detail') }}
            >
              <CardContent className="p-4">
                <div className="flex items-start justify-between gap-2">
                  <div className="min-w-0">
                    <div className="flex items-center gap-2 mb-0.5">
                      <span className="font-mono text-sm font-medium">{inv.number}</span>
                      <Badge variant={STATUS_VARIANTS[inv.status]}>
                        {STATUS_LABELS[inv.status]}
                      </Badge>
                    </div>
                    <p className="font-medium truncate">{inv.clientName || '—'}</p>
                    <p className="text-xs text-muted-foreground">
                      {format(new Date(inv.date), 'd MMMM yyyy', { locale: ru })}
                    </p>
                  </div>
                  <div className="text-right shrink-0">
                    <p className="font-bold text-primary">{formatCurrency(inv.total)}</p>
                    <p className="text-xs text-muted-foreground">{inv.items.length} позиц.</p>
                  </div>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>
      )}
    </div>
  )
}
