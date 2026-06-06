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

// Brand color for Акцент (dark teal from logo)
const BRAND = '#1e3a4a'
const BRAND_LIGHT = '#f0f4f7'

export function InvoiceView({ invoice, onBack, onUpdateStatus, onDelete }: Props) {
  const settings = useLiveQuery(() => db.settings.toArray().then((s) => s[0]))
  const { printRef, handlePrint } = usePrint()

  const invoiceDate = new Date(invoice.date)
  const formattedDate = format(invoiceDate, 'd MMMM yyyy', { locale: ru })

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

      {/* ===================== PRINT + SCREEN CONTENT ===================== */}
      <div ref={printRef}>

        {/* ============================================================== */}
        {/* PRINT-ONLY: Full branded invoice template                        */}
        {/* ============================================================== */}
        <div className="hidden print:block" style={{ fontFamily: 'system-ui, Arial, sans-serif', fontSize: 11, color: '#1a1a1a', lineHeight: 1.5 }}>

          {/* ── Header ─────────────────────────────────────────────────── */}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', paddingBottom: 14, borderBottom: `3px solid ${BRAND}`, marginBottom: 14 }}>

            {/* Left: brand */}
            <div>
              <div style={{ fontFamily: 'Georgia, "Times New Roman", serif', fontSize: 34, fontWeight: 700, color: BRAND, lineHeight: 1, letterSpacing: -1 }}>
                Акцент
              </div>
              <div style={{ fontSize: 8.5, color: '#888', letterSpacing: 2.5, textTransform: 'uppercase', marginTop: 3 }}>
                Художественная студия &amp; Салон декора
              </div>
              {settings && (
                <div style={{ marginTop: 10, fontSize: 10, color: '#444', lineHeight: 1.7 }}>
                  <div style={{ fontWeight: 600 }}>{settings.name}</div>
                  <div>
                    {settings.inn && `ИНН: ${settings.inn}`}
                    {settings.kpp && ` · КПП: ${settings.kpp}`}
                    {settings.ogrn && ` · ОГРН: ${settings.ogrn}`}
                  </div>
                  {settings.address && <div>{settings.address}</div>}
                  {settings.phone && <div>Тел: {settings.phone}</div>}
                </div>
              )}
            </div>

            {/* Right: invoice title */}
            <div style={{ textAlign: 'right' }}>
              <div style={{ fontSize: 13, fontWeight: 700, color: BRAND, textTransform: 'uppercase', letterSpacing: 1 }}>
                Расходная накладная
              </div>
              <div style={{ fontSize: 24, fontWeight: 800, color: BRAND, marginTop: 2 }}>
                № {invoice.number}
              </div>
              <div style={{ fontSize: 11, color: '#666', marginTop: 3 }}>
                от {formattedDate}
              </div>
              <div style={{ marginTop: 8, display: 'inline-block', padding: '2px 10px', borderRadius: 12, fontSize: 10, fontWeight: 600, backgroundColor: invoice.status === 'paid' ? '#dcfce7' : invoice.status === 'sent' ? '#fef9c3' : '#f3f4f6', color: invoice.status === 'paid' ? '#166534' : invoice.status === 'sent' ? '#854d0e' : '#374151' }}>
                {STATUS_LABELS[invoice.status]}
              </div>
            </div>
          </div>

          {/* ── Client ─────────────────────────────────────────────────── */}
          <div style={{ backgroundColor: BRAND_LIGHT, border: `1px solid #d1dde6`, borderRadius: 4, padding: '10px 14px', marginBottom: 14 }}>
            <div style={{ fontSize: 8.5, fontWeight: 700, color: '#888', textTransform: 'uppercase', letterSpacing: 2, marginBottom: 4 }}>
              Покупатель
            </div>
            <div style={{ fontSize: 14, fontWeight: 700, color: '#1a1a1a' }}>{invoice.clientName}</div>
            {(invoice.clientPhone || invoice.clientAddress) && (
              <div style={{ color: '#555', marginTop: 3, fontSize: 10.5 }}>
                {invoice.clientPhone}
                {invoice.clientPhone && invoice.clientAddress && '  ·  '}
                {invoice.clientAddress}
              </div>
            )}
          </div>

          {/* ── Items table ────────────────────────────────────────────── */}
          <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: 12, fontSize: 11 }}>
            <thead>
              <tr style={{ backgroundColor: BRAND, color: 'white' }}>
                <th style={{ padding: '7px 8px', textAlign: 'center', width: 28, fontWeight: 600, fontSize: 10 }}>№</th>
                <th style={{ padding: '7px 10px', textAlign: 'left', fontWeight: 600 }}>Наименование</th>
                <th style={{ padding: '7px 8px', textAlign: 'right', width: 55, fontWeight: 600 }}>Кол-во</th>
                <th style={{ padding: '7px 8px', textAlign: 'center', width: 36, fontWeight: 600 }}>Ед.</th>
                <th style={{ padding: '7px 10px', textAlign: 'right', width: 80, fontWeight: 600 }}>Цена, ₽</th>
                <th style={{ padding: '7px 10px', textAlign: 'right', width: 90, fontWeight: 600 }}>Сумма, ₽</th>
              </tr>
            </thead>
            <tbody>
              {invoice.items.map((item, idx) => (
                <tr key={idx} style={{ borderBottom: '1px solid #dde3e8', backgroundColor: idx % 2 === 0 ? 'white' : '#fafbfc' }}>
                  <td style={{ padding: '6px 8px', textAlign: 'center', color: '#aaa', fontSize: 10 }}>{idx + 1}</td>
                  <td style={{ padding: '6px 10px', fontWeight: 500 }}>{item.productName}</td>
                  <td style={{ padding: '6px 8px', textAlign: 'right' }}>{item.quantity}</td>
                  <td style={{ padding: '6px 8px', textAlign: 'center', color: '#777' }}>{item.unit}</td>
                  <td style={{ padding: '6px 10px', textAlign: 'right' }}>{formatCurrency(item.price)}</td>
                  <td style={{ padding: '6px 10px', textAlign: 'right', fontWeight: 600 }}>{formatCurrency(item.quantity * item.price)}</td>
                </tr>
              ))}
            </tbody>
          </table>

          {/* ── Totals ─────────────────────────────────────────────────── */}
          <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 16 }}>
            <div style={{ width: 290, fontSize: 11 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', borderBottom: '1px solid #e5e9ec' }}>
                <span style={{ color: '#666' }}>Подытог</span>
                <span>{formatCurrency(invoice.subtotal)}</span>
              </div>
              {invoice.discount > 0 && (
                <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', borderBottom: '1px solid #e5e9ec', color: '#c00' }}>
                  <span>Скидка</span>
                  <span>−{formatCurrency(invoice.discount)}</span>
                </div>
              )}
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '8px 12px', backgroundColor: BRAND, color: 'white', fontWeight: 700, fontSize: 13, borderRadius: 3, marginTop: 4 }}>
                <span>ИТОГО</span>
                <span style={{ fontSize: 16 }}>{formatCurrency(invoice.total)}</span>
              </div>
            </div>
          </div>

          {/* ── Notes ──────────────────────────────────────────────────── */}
          {invoice.notes && (
            <div style={{ fontSize: 10, color: '#555', backgroundColor: '#fafbfc', border: '1px solid #e5e9ec', borderRadius: 3, padding: '8px 12px', marginBottom: 16 }}>
              <strong>Примечания:</strong> {invoice.notes}
            </div>
          )}

          {/* ── Signatures ─────────────────────────────────────────────── */}
          <div style={{ display: 'flex', gap: 40, marginTop: 20, marginBottom: 16, fontSize: 10.5, color: '#444' }}>
            <div style={{ flex: 1 }}>
              <div style={{ marginBottom: 18 }}>Отпустил: ___________________________ /_______________/</div>
              <div style={{ color: '#999', fontSize: 9, marginTop: -14 }}>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(подпись)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(ФИО)</div>
            </div>
            <div style={{ flex: 1 }}>
              <div style={{ marginBottom: 18 }}>Получил: _____________________________ /_______________/</div>
              <div style={{ color: '#999', fontSize: 9, marginTop: -14 }}>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(подпись)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(ФИО)</div>
            </div>
          </div>

          {/* ── Bank details ───────────────────────────────────────────── */}
          {settings?.bankName && (
            <div style={{ fontSize: 9.5, color: '#444', border: '1px solid #d1dde6', borderRadius: 3, padding: '8px 12px', marginBottom: 10, backgroundColor: '#fafbfc', borderTop: `2px solid ${BRAND}` }}>
              <div style={{ fontWeight: 700, color: BRAND, marginBottom: 4, fontSize: 9, textTransform: 'uppercase', letterSpacing: 1 }}>Банковские реквизиты</div>
              <div>Банк: <strong>{settings.bankName}</strong></div>
              <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0 24px', marginTop: 2 }}>
                {settings.bankAccount && <span>Р/с: {settings.bankAccount}</span>}
                {settings.bankBik && <span>БИК: {settings.bankBik}</span>}
                {settings.bankCorrAccount && <span>К/с: {settings.bankCorrAccount}</span>}
                {settings.bankInn && <span>ИНН банка: {settings.bankInn}</span>}
                {settings.bankKpp && <span>КПП банка: {settings.bankKpp}</span>}
              </div>
            </div>
          )}

          {/* ── Ad footer ──────────────────────────────────────────────── */}
          {settings?.adText && (
            <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '7px 12px', borderLeft: `3px solid ${BRAND}`, backgroundColor: BRAND_LIGHT, fontSize: 10, color: BRAND, fontStyle: 'italic' }}>
              <span style={{ fontSize: 14 }}>✦</span>
              <span>{settings.adText}</span>
            </div>
          )}
        </div>

        {/* ============================================================== */}
        {/* SCREEN-ONLY: Card layout                                        */}
        {/* ============================================================== */}
        <div className="print:hidden rounded-xl border border-border bg-card p-5 space-y-4">

          {/* Invoice header */}
          <div className="flex justify-between items-start">
            <div>
              <h2 className="text-lg font-bold">Расходная накладная</h2>
              <p className="text-sm font-mono text-muted-foreground">{invoice.number}</p>
            </div>
            <div className="text-right text-sm text-muted-foreground">
              <p>{formattedDate}</p>
            </div>
          </div>

          {/* Client */}
          <div className="rounded-md bg-muted/50 p-3 text-sm space-y-1">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1">Покупатель</p>
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
                    <td className="px-3 py-2">{item.productName}</td>
                    <td className="px-3 py-2 text-right">{item.quantity} {item.unit}</td>
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
