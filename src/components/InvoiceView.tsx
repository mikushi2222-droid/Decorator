import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency } from '@/lib/utils'
import { format } from 'date-fns'
import { ru } from 'date-fns/locale'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft, Printer, Trash2, CheckCircle, Send } from 'lucide-react'
import type { Invoice } from '@/types'
import { usePrint } from '@/hooks/usePrint'

interface Props {
  invoice: Invoice
  onBack: () => void
  onUpdateStatus: (status: Invoice['status']) => void
  onDelete: () => void
}

const STATUS_LABELS: Record<string, string> = { draft: 'Черновик', sent: 'Выставлена', paid: 'Оплачена' }
const STATUS_VARIANTS: Record<string, 'outline' | 'warning' | 'success'> = {
  draft: 'outline',
  sent: 'warning',
  paid: 'success',
}

export function InvoiceView({ invoice, onBack, onUpdateStatus, onDelete }: Props) {
  const settings = useLiveQuery(() => db.settings.toArray().then((s) => s[0]))
  const { printRef, handlePrint } = usePrint()

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      {/* Actions bar */}
      <div className="flex items-center gap-2 no-print">
        <button onClick={onBack} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <span className="font-mono font-medium">{invoice.number}</span>
        <Badge variant={STATUS_VARIANTS[invoice.status]}>{STATUS_LABELS[invoice.status]}</Badge>
        <div className="ml-auto flex gap-2">
          <Button size="sm" variant="outline" onClick={() => handlePrint()}>
            <Printer className="h-4 w-4" />
          </Button>
          <Button size="sm" variant="destructive" onClick={onDelete} title="Удалить накладную">
            <Trash2 className="h-4 w-4" />
          </Button>
        </div>
      </div>

      {/* Status progression */}
      <div className="flex gap-2 no-print">
        {invoice.status === 'draft' && (
          <Button size="sm" className="flex-1" onClick={() => onUpdateStatus('sent')}>
            <Send className="h-4 w-4" /> Выставить клиенту
          </Button>
        )}
        {invoice.status === 'sent' && (
          <Button size="sm" className="flex-1" onClick={() => onUpdateStatus('paid')}>
            <CheckCircle className="h-4 w-4" /> Отметить оплаченной
          </Button>
        )}
      </div>

      {/* Printable invoice */}
      <div ref={printRef} className="space-y-4">
        {/* Store header (visible on print) */}
        {settings && (
          <div className="hidden print:block border-b border-gray-300 pb-4 mb-4">
            <h1 className="text-2xl font-bold">{settings.name}</h1>
            <p className="text-sm text-gray-600">{settings.address}</p>
            <p className="text-sm text-gray-600">{settings.phone}</p>
            {settings.inn && <p className="text-sm text-gray-600">ИНН: {settings.inn}</p>}
          </div>
        )}

        <div className="rounded-xl border border-border bg-card p-5 space-y-4">
          {/* Invoice header */}
          <div className="flex justify-between items-start">
            <div>
              <h2 className="text-lg font-bold">Расходная накладная</h2>
              <p className="text-sm font-mono text-muted-foreground">{invoice.number}</p>
            </div>
            <div className="text-right text-sm text-muted-foreground">
              <p>{format(new Date(invoice.date), 'd MMMM yyyy', { locale: ru })}</p>
            </div>
          </div>

          {/* Client */}
          <div className="rounded-md bg-muted/50 p-3 text-sm space-y-1">
            <p className="font-medium">{invoice.clientName}</p>
            {invoice.clientPhone && <p className="text-muted-foreground">{invoice.clientPhone}</p>}
            {invoice.clientAddress && <p className="text-muted-foreground">{invoice.clientAddress}</p>}
          </div>

          {/* Items table */}
          <div className="rounded-md border border-border overflow-hidden">
            <table className="w-full text-sm">
              <thead className="bg-muted/50">
                <tr>
                  <th className="text-left px-3 py-2 font-medium">Наименование</th>
                  <th className="text-right px-3 py-2 font-medium w-16">Кол-во</th>
                  <th className="text-right px-3 py-2 font-medium w-20">Цена</th>
                  <th className="text-right px-3 py-2 font-medium w-20">Сумма</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-border">
                {invoice.items.map((item, idx) => (
                  <tr key={idx}>
                    <td className="px-3 py-2">
                      {item.productName}
                    </td>
                    <td className="px-3 py-2 text-right">
                      {item.quantity} {item.unit}
                    </td>
                    <td className="px-3 py-2 text-right">{formatCurrency(item.price)}</td>
                    <td className="px-3 py-2 text-right font-medium">{formatCurrency(item.quantity * item.price)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Totals */}
          <div className="space-y-1 text-sm">
            <div className="flex justify-between">
              <span className="text-muted-foreground">Подытог</span>
              <span>{formatCurrency(invoice.subtotal)}</span>
            </div>
            {invoice.discount > 0 && (
              <div className="flex justify-between">
                <span className="text-muted-foreground">Скидка</span>
                <span className="text-destructive">−{formatCurrency(invoice.discount)}</span>
              </div>
            )}
            <div className="flex justify-between font-bold text-base border-t border-border pt-2 mt-2">
              <span>ИТОГО</span>
              <span className="text-primary">{formatCurrency(invoice.total)}</span>
            </div>
          </div>

          {invoice.notes && (
            <div className="rounded-md bg-muted/50 p-3 text-sm">
              <p className="text-xs text-muted-foreground mb-1">Примечания</p>
              <p>{invoice.notes}</p>
            </div>
          )}
        </div>
      </div>
    </div>
  )
}
