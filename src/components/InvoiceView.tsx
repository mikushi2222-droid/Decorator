import { useRef, useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency } from '@/lib/utils'
import { format } from 'date-fns'
import { ru } from 'date-fns/locale'
import { Button } from '@/components/ui/button'
import { Badge } from '@/components/ui/badge'
import { ArrowLeft, Printer, Trash2, CheckCircle, Send, FileDown, FileText, Loader2 } from 'lucide-react'
import type { Invoice } from '@/types'
import { usePrint } from '@/hooks/usePrint'
import { downloadAsPDF, downloadAsDOCX } from '@/lib/exportInvoice'

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

const BRAND = '#1e3a4a'
const BRAND_LIGHT = '#f0f4f7'

export function InvoiceView({ invoice, onBack, onUpdateStatus, onDelete }: Props) {
  const settings = useLiveQuery(() => db.settings.toArray().then((s) => s[0]))
  const { printRef, handlePrint } = usePrint()
  const captureRef = useRef<HTMLDivElement>(null)
  const [downloading, setDownloading] = useState<'pdf' | 'docx' | null>(null)

  const invoiceDate = new Date(invoice.date)
  const formattedDate = format(invoiceDate, 'd MMMM yyyy', { locale: ru })

  const handleDownloadPDF = async () => {
    if (!captureRef.current) return
    setDownloading('pdf')
    try {
      await downloadAsPDF(invoice.number, captureRef.current)
    } finally {
      setDownloading(null)
    }
  }

  const handleDownloadDOCX = async () => {
    setDownloading('docx')
    try {
      await downloadAsDOCX(invoice, settings)
    } finally {
      setDownloading(null)
    }
  }

  // The print template — used both inside printRef (for browser print)
  // and as captureRef target (for PDF/DOCX capture).
  const PrintTemplate = () => (
    <div style={{ fontFamily: 'system-ui, Arial, sans-serif', fontSize: 11, color: '#1a1a1a', lineHeight: 1.5, backgroundColor: '#fff', padding: 24 }}>

      {/* Top accent bar */}
      <div style={{ height: 5, backgroundColor: BRAND, margin: '-24px -24px 20px', borderRadius: '3px 3px 0 0' }} />

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', paddingBottom: 14, borderBottom: `2px solid ${BRAND}`, marginBottom: 16 }}>
        {/* Left: logo + org */}
        <div style={{ display: 'flex', alignItems: 'flex-start', gap: 12 }}>
          <img src="/logo-akcent.jpg" alt="Акцент" style={{ width: 86, height: 86, borderRadius: 10, objectFit: 'cover', flexShrink: 0, border: `2px solid ${BRAND}` }} />
          <div style={{ paddingTop: 2 }}>
            {settings && (
              <div style={{ fontSize: 10.5, color: '#333', lineHeight: 1.75 }}>
                <div style={{ fontWeight: 700, fontSize: 13, color: BRAND, marginBottom: 2 }}>{settings.name}</div>
                <div>
                  {settings.inn && `ИНН: ${settings.inn}`}
                  {settings.kpp && ` · КПП: ${settings.kpp}`}
                </div>
                {settings.ogrn && <div>ОГРН: {settings.ogrn}</div>}
                {settings.address && <div>{settings.address}</div>}
                {settings.phone && <div>Тел: {settings.phone}</div>}
              </div>
            )}
          </div>
        </div>

        {/* Right: invoice meta */}
        <div style={{ textAlign: 'right', paddingTop: 4 }}>
          <div style={{ fontSize: 10, fontWeight: 700, color: BRAND, textTransform: 'uppercase', letterSpacing: 2 }}>
            Расходная накладная
          </div>
          <div style={{ fontSize: 28, fontWeight: 800, color: BRAND, marginTop: 2, letterSpacing: -0.5, lineHeight: 1 }}>
            № {invoice.number}
          </div>
          <div style={{ fontSize: 11, color: '#666', marginTop: 5 }}>
            от {formattedDate}
          </div>
          <div style={{ marginTop: 8, display: 'inline-block', padding: '3px 12px', borderRadius: 12, fontSize: 10, fontWeight: 600, border: `1px solid ${BRAND}`, color: BRAND, backgroundColor: BRAND_LIGHT }}>
            {STATUS_LABELS[invoice.status]}
          </div>
        </div>
      </div>

      {/* Client */}
      <div style={{ backgroundColor: BRAND_LIGHT, border: `1px solid #cdd8e0`, borderRadius: 5, padding: '10px 14px', marginBottom: 16 }}>
        <div style={{ fontSize: 8.5, fontWeight: 700, color: '#999', textTransform: 'uppercase', letterSpacing: 2.5, marginBottom: 5 }}>
          Покупатель
        </div>
        <div style={{ fontSize: 15, fontWeight: 700, color: '#1a1a1a' }}>{invoice.clientName}</div>
        {(invoice.clientPhone || invoice.clientAddress) && (
          <div style={{ color: '#555', marginTop: 3, fontSize: 10.5 }}>
            {invoice.clientPhone}
            {invoice.clientPhone && invoice.clientAddress && '  ·  '}
            {invoice.clientAddress}
          </div>
        )}
      </div>

      {/* Items table */}
      <table style={{ width: '100%', borderCollapse: 'collapse', marginBottom: 14, fontSize: 11 }}>
        <thead>
          <tr style={{ backgroundColor: BRAND, color: 'white' }}>
            {[['№', 'center', 28], ['Наименование', 'left', 'auto'], ['Кол-во', 'right', 60], ['Ед.', 'center', 38], ['Цена, ₽', 'right', 82], ['Сумма, ₽', 'right', 92]].map(([label, align, w]) => (
              <th key={label as string} style={{ padding: '8px 9px', textAlign: align as any, width: w, fontWeight: 600, fontSize: 10.5 }}>{label}</th>
            ))}
          </tr>
        </thead>
        <tbody>
          {invoice.items.map((item, idx) => (
            <tr key={idx} style={{ borderBottom: '1px solid #e0e6eb', backgroundColor: idx % 2 === 0 ? '#fff' : '#fafbfc' }}>
              <td style={{ padding: '6px 9px', textAlign: 'center', color: '#bbb', fontSize: 10 }}>{idx + 1}</td>
              <td style={{ padding: '6px 9px', fontWeight: 500 }}>{item.productName}</td>
              <td style={{ padding: '6px 9px', textAlign: 'right' }}>{item.quantity}</td>
              <td style={{ padding: '6px 9px', textAlign: 'center', color: '#777' }}>{item.unit}</td>
              <td style={{ padding: '6px 9px', textAlign: 'right' }}>{formatCurrency(item.price)}</td>
              <td style={{ padding: '6px 9px', textAlign: 'right', fontWeight: 600 }}>{formatCurrency(item.quantity * item.price)}</td>
            </tr>
          ))}
        </tbody>
      </table>

      {/* Totals */}
      <div style={{ display: 'flex', justifyContent: 'flex-end', marginBottom: 18 }}>
        <div style={{ width: 295, fontSize: 11 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', borderBottom: '1px solid #e0e6eb' }}>
            <span style={{ color: '#777' }}>Подытог</span>
            <span>{formatCurrency(invoice.subtotal)}</span>
          </div>
          {invoice.discount > 0 && (
            <div style={{ display: 'flex', justifyContent: 'space-between', padding: '4px 0', borderBottom: '1px solid #e0e6eb', color: '#c00' }}>
              <span>Скидка</span>
              <span>−{formatCurrency(invoice.discount)}</span>
            </div>
          )}
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', padding: '9px 14px', backgroundColor: BRAND, color: '#fff', fontWeight: 700, fontSize: 14, borderRadius: 4, marginTop: 5 }}>
            <span>ИТОГО</span>
            <span style={{ fontSize: 17 }}>{formatCurrency(invoice.total)}</span>
          </div>
        </div>
      </div>

      {/* Notes */}
      {invoice.notes && (
        <div style={{ fontSize: 10.5, color: '#555', backgroundColor: '#fafbfc', border: '1px solid #e0e6eb', borderRadius: 4, padding: '8px 12px', marginBottom: 18 }}>
          <strong>Примечания:</strong> {invoice.notes}
        </div>
      )}

      {/* Signatures */}
      <div style={{ display: 'flex', gap: 40, marginTop: 20, marginBottom: 18, fontSize: 11, color: '#444', borderTop: '1px solid #ddd', paddingTop: 14 }}>
        <div style={{ flex: 1 }}>
          <div>Отпустил: ___________________________ /_______________/</div>
          <div style={{ color: '#bbb', fontSize: 8.5, marginTop: 2, paddingLeft: 68 }}>(подпись)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(ФИО)</div>
        </div>
        <div style={{ flex: 1 }}>
          <div>Получил: _____________________________ /_______________/</div>
          <div style={{ color: '#bbb', fontSize: 8.5, marginTop: 2, paddingLeft: 68 }}>(подпись)&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;(ФИО)</div>
        </div>
      </div>

      {/* Bank details */}
      {settings?.bankName && (
        <div style={{ fontSize: 10, color: '#444', border: '1px solid #cdd8e0', borderTop: `3px solid ${BRAND}`, borderRadius: 4, padding: '10px 13px', marginBottom: 12, backgroundColor: '#fafbfc' }}>
          <div style={{ fontWeight: 700, color: BRAND, marginBottom: 5, fontSize: 9, textTransform: 'uppercase', letterSpacing: 1.5 }}>Банковские реквизиты</div>
          <div>Банк: <strong>{settings.bankName}</strong></div>
          <div style={{ display: 'flex', flexWrap: 'wrap', gap: '0 28px', marginTop: 3 }}>
            {settings.bankAccount && <span>Р/с: {settings.bankAccount}</span>}
            {settings.bankBik && <span>БИК: {settings.bankBik}</span>}
            {settings.bankCorrAccount && <span>К/с: {settings.bankCorrAccount}</span>}
            {settings.bankInn && <span>ИНН банка: {settings.bankInn}</span>}
            {settings.bankKpp && <span>КПП банка: {settings.bankKpp}</span>}
          </div>
        </div>
      )}

      {/* Ad footer */}
      {settings?.adText && (
        <div style={{ display: 'flex', alignItems: 'center', gap: 10, padding: '8px 14px', borderLeft: `4px solid ${BRAND}`, backgroundColor: BRAND_LIGHT, fontSize: 10.5, color: BRAND, fontStyle: 'italic' }}>
          <span style={{ fontSize: 16, flexShrink: 0 }}>✦</span>
          <span>{settings.adText}</span>
        </div>
      )}
    </div>
  )

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">

      {/* Actions bar */}
      <div className="flex items-center gap-2 no-print">
        <button onClick={onBack} className="text-muted-foreground hover:text-foreground p-1">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <span className="font-mono font-medium text-sm">{invoice.number}</span>
        <Badge variant={STATUS_VARIANTS[invoice.status]}>{STATUS_LABELS[invoice.status]}</Badge>
        <div className="ml-auto flex items-center gap-1.5">
          <Button size="sm" variant="outline" onClick={() => handlePrint()} title="Печать">
            <Printer className="h-4 w-4" />
          </Button>
          <Button size="sm" variant="outline" onClick={handleDownloadPDF} disabled={!!downloading} title="Скачать PDF">
            {downloading === 'pdf' ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileDown className="h-4 w-4" />}
            <span className="ml-1 text-xs">PDF</span>
          </Button>
          <Button size="sm" variant="outline" onClick={handleDownloadDOCX} disabled={!!downloading} title="Скачать Word (.docx)">
            {downloading === 'docx' ? <Loader2 className="h-4 w-4 animate-spin" /> : <FileText className="h-4 w-4" />}
            <span className="ml-1 text-xs">Word</span>
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

      {/* PRINT: uses react-to-print */}
      <div ref={printRef}>
        <div className="hidden print:block">
          <PrintTemplate />
        </div>
        {/* SCREEN: card view */}
        <div className="print:hidden rounded-xl border border-border bg-card p-5 space-y-4">
          <div className="flex justify-between items-start">
            <div>
              <h2 className="text-lg font-bold">Расходная накладная</h2>
              <p className="text-sm font-mono text-muted-foreground">{invoice.number}</p>
            </div>
            <div className="text-right text-sm text-muted-foreground">
              <p>{formattedDate}</p>
            </div>
          </div>
          <div className="rounded-md bg-muted/50 p-3 text-sm space-y-1">
            <p className="text-xs font-semibold text-muted-foreground uppercase tracking-wide mb-1">Покупатель</p>
            <p className="font-medium">{invoice.clientName}</p>
            {invoice.clientPhone && <p className="text-muted-foreground">{invoice.clientPhone}</p>}
            {invoice.clientAddress && <p className="text-muted-foreground">{invoice.clientAddress}</p>}
          </div>
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

      {/* OFF-SCREEN capture target for PDF (separate from printRef) */}
      <div ref={captureRef} className="hidden">
        <PrintTemplate />
      </div>
    </div>
  )
}
