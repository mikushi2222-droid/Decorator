export type InvoiceStatus = 'draft' | 'sent' | 'paid'

export interface Client {
  id?: number
  name: string
  phone: string
  address: string
  createdAt: Date
}

export interface Product {
  id?: number
  name: string
  unit: string
  price: number
  coverage: number // кг или л на м²
  category: string
  description: string
}

export interface InvoiceItem {
  productId?: number
  productName: string
  unit: string
  quantity: number
  price: number
}

export interface Invoice {
  id?: number
  number: string
  date: Date
  clientName: string
  clientPhone: string
  clientAddress: string
  items: InvoiceItem[]
  subtotal: number
  discount: number
  total: number
  status: InvoiceStatus
  notes: string
  createdAt: Date
}

export interface LaborRate {
  id?: number
  name: string
  pricePerSqm: number
  unit: string
}

export interface StoreSettings {
  id?: number
  name: string
  address: string
  phone: string
  inn: string
  logo: string
}

export interface PlasterType {
  id: string
  name: string
  brand: string
  coverageKgPerSqm: number
  layerMm: number
  pricePerKg: number
  surfaces: string[]
  rooms: string[]
  style: string[]
  description: string
  pros: string[]
  dryingTime: string
}

export type CalcMode = 'material' | 'labor' | 'both'
