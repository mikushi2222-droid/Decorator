import { type ClassValue, clsx } from 'clsx'
import { twMerge } from 'tailwind-merge'

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs))
}

export function formatCurrency(amount: number): string {
  // Всегда 2 знака — чтобы экран совпадал с PDF/DOCX-экспортом и не было
  // расхождений в отображении одной и той же суммы.
  return new Intl.NumberFormat('ru-RU', {
    style: 'currency',
    currency: 'RUB',
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  }).format(amount)
}

export function formatNumber(n: number, decimals = 2): string {
  return new Intl.NumberFormat('ru-RU', {
    minimumFractionDigits: 0,
    maximumFractionDigits: decimals,
  }).format(n)
}

export function generateInvoiceNumber(lastNumber: number): string {
  const year = new Date().getFullYear()
  const num = String(lastNumber + 1).padStart(4, '0')
  return `ДК-${year}-${num}`
}
