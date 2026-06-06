import type { Invoice, StoreSettings } from '@/types'
import { format } from 'date-fns'
import { ru } from 'date-fns/locale'

const BRAND = '1E3A4A'

function rub(n: number): string {
  return new Intl.NumberFormat('ru-RU', { minimumFractionDigits: 2, maximumFractionDigits: 2 }).format(n) + ' ₽'
}

const STATUS_RU: Record<string, string> = { draft: 'Черновик', sent: 'Выставлена', paid: 'Оплачена' }

// ─── PDF ────────────────────────────────────────────────────────────────────

export async function downloadAsPDF(
  invoiceNumber: string,
  printTemplateEl: HTMLElement
): Promise<void> {
  const [{ default: html2canvas }, { default: jsPDF }] = await Promise.all([
    import('html2canvas'),
    import('jspdf'),
  ])

  // Move element off-screen and make it visible for capture
  const s = printTemplateEl.style
  const saved = { display: s.display, width: s.width, position: s.position, left: s.left, top: s.top }
  s.display = 'block'
  s.width = '800px'
  s.position = 'fixed'
  s.left = '-10000px'
  s.top = '0'

  await new Promise<void>((r) => setTimeout(r, 120))

  const canvas = await html2canvas(printTemplateEl, {
    scale: 2,
    useCORS: true,
    allowTaint: true,
    backgroundColor: '#ffffff',
    logging: false,
  })

  s.display = saved.display
  s.width = saved.width
  s.position = saved.position
  s.left = saved.left
  s.top = saved.top

  const pdf = new jsPDF({ orientation: 'portrait', unit: 'mm', format: 'a4' })
  const margin = 10
  const availW = 210 - margin * 2
  const availH = 297 - margin * 2
  const aspect = canvas.height / canvas.width
  let w = availW
  let h = w * aspect
  if (h > availH) { h = availH; w = h / aspect }
  pdf.addImage(canvas.toDataURL('image/jpeg', 0.93), 'JPEG', margin + (availW - w) / 2, margin, w, h)
  pdf.save(`${invoiceNumber}.pdf`)
}

// ─── DOCX ───────────────────────────────────────────────────────────────────

export async function downloadAsDOCX(
  invoice: Invoice,
  settings?: StoreSettings
): Promise<void> {
  const docx = await import('docx')
  const {
    Document, Packer, Paragraph, Table, TableRow, TableCell,
    TextRun, AlignmentType, BorderStyle, WidthType, ShadingType,
    TableLayoutType,
  } = docx

  type TRun = ConstructorParameters<typeof TextRun>[0]
  type PArgs = ConstructorParameters<typeof Paragraph>[0]

  const fmtDate = format(new Date(invoice.date), 'd MMMM yyyy г.', { locale: ru })

  // helpers — typed locally to avoid the Omit<string|IRunOptions> issue
  const run = (text: string, opts: { bold?: boolean; italics?: boolean; size?: number; color?: string; allCaps?: boolean } = {}) =>
    new TextRun({ text, ...opts } as TRun)

  const par = (opts: PArgs) => new Paragraph(opts)
  const space = (after: number) => par({ children: [run('')], spacing: { after } })

  const ALIGNS = [AlignmentType.CENTER, AlignmentType.LEFT, AlignmentType.RIGHT, AlignmentType.CENTER, AlignmentType.RIGHT, AlignmentType.RIGHT]
  const WIDTHS = [5, 43, 10, 7, 17, 18]

  // ── Organization ──────────────────────────────────────────────────────────
  const orgLines = [
    par({ children: [run(settings?.name || 'ООО "АКЦЕНТ"', { bold: true, size: 28, color: BRAND })] }),
    par({ children: [run('Художественная студия & Салон декора', { size: 16, color: '888888', italics: true })], spacing: { after: 40 } }),
    ...[settings?.inn && `ИНН: ${settings.inn}`, settings?.kpp && `КПП: ${settings.kpp}`, settings?.ogrn && `ОГРН: ${settings.ogrn}`].filter(Boolean).length
      ? [par({ children: [run([settings?.inn && `ИНН: ${settings.inn}`, settings?.kpp && `КПП: ${settings.kpp}`, settings?.ogrn && `ОГРН: ${settings.ogrn}`].filter(Boolean).join('  ·  '), { size: 15, color: '555555' })], spacing: { after: 20 } })]
      : [],
    ...settings?.address ? [par({ children: [run(settings.address, { size: 15, color: '555555' })], spacing: { after: 20 } })] : [],
    ...settings?.phone ? [par({ children: [run(`Тел: ${settings.phone}`, { size: 15, color: '555555' })], spacing: { after: 100 } })] : [],
  ]

  // ── Invoice title ─────────────────────────────────────────────────────────
  const titleLines = [
    par({ children: [run('РАСХОДНАЯ НАКЛАДНАЯ', { bold: true, size: 20, color: BRAND })], alignment: AlignmentType.RIGHT, spacing: { after: 20 } }),
    par({ children: [run(`№ ${invoice.number}`, { bold: true, size: 38, color: BRAND })], alignment: AlignmentType.RIGHT, spacing: { after: 20 } }),
    par({ children: [run(`от ${fmtDate}`, { size: 18, color: '666666' })], alignment: AlignmentType.RIGHT, spacing: { after: 20 } }),
    par({ children: [run(`Статус: ${STATUS_RU[invoice.status] || invoice.status}`, { size: 16, color: '888888' })], alignment: AlignmentType.RIGHT, spacing: { after: 280 } }),
  ]

  // ── Client ────────────────────────────────────────────────────────────────
  const clientLines = [
    par({ children: [run('ПОКУПАТЕЛЬ', { bold: true, size: 14, color: '999999' })], spacing: { after: 60 } }),
    par({ children: [run(invoice.clientName, { bold: true, size: 24, color: '1A1A1A' })], spacing: { after: 40 } }),
    ...invoice.clientPhone ? [par({ children: [run(invoice.clientPhone, { size: 17, color: '555555' })], spacing: { after: 20 } })] : [],
    ...invoice.clientAddress ? [par({ children: [run(invoice.clientAddress, { size: 17, color: '555555' })], spacing: { after: 200 } })] : [space(200)],
  ]

  // ── Items table ───────────────────────────────────────────────────────────
  const HEADERS = ['№', 'Наименование', 'Кол-во', 'Ед.', 'Цена, ₽', 'Сумма, ₽']

  const mkCell = (text: string, alignIdx: number, bold = false, header = false) =>
    new TableCell({
      children: [par({ children: [run(text, { bold, size: 16, color: header ? 'FFFFFF' : '1A1A1A' })], alignment: ALIGNS[alignIdx] })],
      ...(header ? { shading: { type: ShadingType.SOLID, fill: BRAND, color: BRAND } } : {}),
      margins: { top: 80, bottom: 80, left: 100, right: 100 },
      width: { size: WIDTHS[alignIdx], type: WidthType.PERCENTAGE },
    })

  const headerRow = new TableRow({
    tableHeader: true,
    children: HEADERS.map((h, i) => mkCell(h, i, true, true)),
  })

  const dataRows = invoice.items.map((item, idx) =>
    new TableRow({
      children: [
        mkCell(String(idx + 1), 0),
        mkCell(item.productName, 1),
        mkCell(String(item.quantity), 2),
        mkCell(item.unit, 3),
        mkCell(rub(item.price), 4),
        mkCell(rub(item.quantity * item.price), 5, true),
      ],
    })
  )

  const itemsTable = new Table({
    layout: TableLayoutType.FIXED,
    width: { size: 100, type: WidthType.PERCENTAGE },
    rows: [headerRow, ...dataRows],
  })

  // ── Totals ────────────────────────────────────────────────────────────────
  const totalsLines = [
    space(160),
    par({ children: [run(`Подытог:  ${rub(invoice.subtotal)}`, { size: 18 })], alignment: AlignmentType.RIGHT, spacing: { after: 40 } }),
    ...invoice.discount > 0 ? [par({ children: [run(`Скидка:  −${rub(invoice.discount)}`, { size: 18, color: 'CC0000' })], alignment: AlignmentType.RIGHT, spacing: { after: 40 } })] : [],
    par({ children: [run(`ИТОГО:  ${rub(invoice.total)}`, { bold: true, size: 30, color: BRAND })], alignment: AlignmentType.RIGHT, spacing: { after: 280 } }),
  ]

  // ── Notes ─────────────────────────────────────────────────────────────────
  const notesLines = invoice.notes
    ? [par({ children: [run(`Примечания: ${invoice.notes}`, { size: 17, italics: true, color: '555555' })], spacing: { before: 80, after: 200 } })]
    : []

  // ── Signatures ────────────────────────────────────────────────────────────
  const sigLines = [
    par({ border: { top: { style: BorderStyle.SINGLE, size: 2, color: 'DDDDDD' } }, spacing: { before: 200, after: 200 } }),
    par({ children: [run('Отпустил: _________________________________ /____________________/', { size: 18 })], spacing: { after: 240 } }),
    par({ children: [run('Получил:  _________________________________ /____________________/', { size: 18 })], spacing: { after: 280 } }),
  ]

  // ── Bank ─────────────────────────────────────────────────────────────────
  const bankLines = settings?.bankName ? [
    par({ border: { top: { style: BorderStyle.THICK, size: 4, color: BRAND } }, spacing: { before: 80 } }),
    par({ children: [run('БАНКОВСКИЕ РЕКВИЗИТЫ', { bold: true, size: 14, color: BRAND })], spacing: { after: 80 } }),
    par({ children: [run(`Банк: ${settings.bankName}`, { bold: true, size: 16 })], spacing: { after: 40 } }),
    par({ children: [run([settings.bankAccount && `Р/с: ${settings.bankAccount}`, settings.bankBik && `БИК: ${settings.bankBik}`, settings.bankCorrAccount && `К/с: ${settings.bankCorrAccount}`].filter(Boolean).join('   ·   '), { size: 16 })], spacing: { after: 40 } }),
    ...[settings.bankInn, settings.bankKpp].some(Boolean)
      ? [par({ children: [run([settings.bankInn && `ИНН банка: ${settings.bankInn}`, settings.bankKpp && `КПП банка: ${settings.bankKpp}`].filter(Boolean).join('   ·   '), { size: 16 })], spacing: { after: 160 } })]
      : [],
  ] : []

  // ── Ad ────────────────────────────────────────────────────────────────────
  const adLines = settings?.adText ? [
    par({
      children: [run(`✦  ${settings.adText}`, { size: 18, color: BRAND, italics: true })],
      border: { left: { style: BorderStyle.SINGLE, size: 8, color: BRAND } },
      indent: { left: 220 },
      spacing: { before: 200, after: 0 },
    }),
  ] : []

  // ── Build document ────────────────────────────────────────────────────────
  const doc = new Document({
    sections: [{
      properties: { page: { margin: { top: 850, right: 850, bottom: 850, left: 850 } } },
      children: [
        ...orgLines,
        ...titleLines,
        par({ border: { bottom: { style: BorderStyle.THICK, size: 6, color: BRAND } }, spacing: { after: 240 } }),
        ...clientLines,
        itemsTable,
        ...totalsLines,
        ...notesLines,
        ...sigLines,
        ...bankLines,
        ...adLines,
      ],
    }],
  })

  const blob = await Packer.toBlob(doc)
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `${invoice.number}.docx`
  a.click()
  setTimeout(() => URL.revokeObjectURL(url), 15000)
}
