import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Textarea } from '@/components/ui/textarea'
import { ArrowLeft, Plus, Trash2, Info } from 'lucide-react'
import type { Invoice, InvoiceItem } from '@/types'

interface Props {
  onSave: (data: Omit<Invoice, 'id' | 'number' | 'createdAt'>) => Promise<void>
  onCancel: () => void
}

const emptyItem = (): InvoiceItem => ({
  productName: '',
  unit: 'кг',
  quantity: 1,
  price: 0,
})

export function InvoiceForm({ onSave, onCancel }: Props) {
  const products = useLiveQuery(() => db.products.toArray(), [])

  const [clientName, setClientName] = useState('')
  const [clientPhone, setClientPhone] = useState('')
  const [clientAddress, setClientAddress] = useState('')
  const [date, setDate] = useState(new Date().toISOString().split('T')[0])
  const [items, setItems] = useState<InvoiceItem[]>([emptyItem()])
  const [discount, setDiscount] = useState('')
  const [notes, setNotes] = useState('')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState('')

  const updateItem = (idx: number, field: keyof InvoiceItem, value: string | number) => {
    setItems((prev) => prev.map((item, i) => i === idx ? { ...item, [field]: value } : item))
  }

  const removeItem = (idx: number) => {
    if (items.length === 1) return
    setItems((prev) => prev.filter((_, i) => i !== idx))
  }

  const addProduct = (productId: string) => {
    const product = products?.find((p) => String(p.id) === productId)
    if (!product) return
    setItems((prev) => [...prev, {
      productId: product.id,
      productName: product.name,
      unit: product.unit,
      quantity: 1,
      price: product.price,
    }])
  }

  const subtotal = items.reduce((s, item) => s + (item.quantity * item.price), 0)
  const discountAmt = parseFloat(discount) || 0
  const total = Math.max(0, subtotal - discountAmt)

  const handleSave = async () => {
    if (!clientName.trim()) {
      setError('Укажите имя клиента — это обязательное поле')
      return
    }
    if (items.some((i) => !i.productName.trim())) {
      setError('Заполните наименование во всех позициях товара')
      return
    }
    if (items.some((i) => i.quantity <= 0)) {
      setError('Количество в каждой позиции должно быть больше нуля')
      return
    }
    setError('')
    setSaving(true)
    try {
      // Парсим дату как локальную полночь (не UTC), чтобы избежать сдвига на −1 день
      await onSave({
        date: new Date(date + 'T00:00:00'),
        clientName,
        clientPhone,
        clientAddress,
        items,
        subtotal,
        discount: discountAmt,
        total,
        status: 'draft',
        notes,
      })
    } catch {
      setError('Ошибка сохранения. Попробуйте ещё раз.')
      setSaving(false)
    }
  }

  const catalogOptions = (products || []).map((p) => ({
    value: String(p.id),
    label: `${p.name} — ${formatCurrency(p.price)}/${p.unit}`,
  }))

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      <div className="flex items-center gap-3">
        <button onClick={onCancel} className="text-muted-foreground hover:text-foreground">
          <ArrowLeft className="h-5 w-5" />
        </button>
        <h1 className="text-xl font-bold">Новая накладная</h1>
      </div>

      {/* Hint */}
      <div className="flex items-start gap-2 rounded-lg bg-muted/60 border border-border px-4 py-3 text-sm text-muted-foreground">
        <Info className="h-4 w-4 shrink-0 mt-0.5 text-primary" />
        <span>Заполните данные клиента и список товаров. Позиции можно добавить из каталога или написать вручную.</span>
      </div>

      {/* Step 1 — Client */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Шаг 1 — Данные клиента</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <Input
            label="Имя / Организация *"
            value={clientName}
            onChange={(e) => setClientName(e.target.value)}
            placeholder="Иванов Иван Иванович"
            hint="Обязательное поле — отображается на накладной"
          />
          <Input
            label="Телефон"
            type="tel"
            value={clientPhone}
            onChange={(e) => setClientPhone(e.target.value)}
            placeholder="+7 (999) 000-00-00"
          />
          <Input
            label="Адрес объекта"
            value={clientAddress}
            onChange={(e) => setClientAddress(e.target.value)}
            placeholder="ул. Примерная, д. 1, кв. 5"
          />
          <Input
            label="Дата накладной"
            type="date"
            value={date}
            onChange={(e) => setDate(e.target.value)}
          />
        </CardContent>
      </Card>

      {/* Step 2 — Items */}
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base">Шаг 2 — Товары и услуги</CardTitle>
            <button
              onClick={() => setItems((prev) => [...prev, emptyItem()])}
              className="flex items-center gap-1 text-sm text-primary hover:underline"
            >
              <Plus className="h-3.5 w-3.5" /> Добавить строку
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {/* Quick add from catalog */}
          {catalogOptions.length > 0 && (
            <div className="space-y-1">
              <Select
                options={catalogOptions}
                value=""
                onChange={(e) => addProduct(e.target.value)}
                placeholder="— Добавить из каталога —"
              />
              <p className="text-xs text-muted-foreground">
                Выберите из каталога — или заполните строки ниже вручную.
              </p>
            </div>
          )}

          {items.map((item, idx) => (
            <div key={idx} className="rounded-lg border border-border p-3 space-y-2">
              <div className="flex items-center justify-between">
                <span className="text-xs font-medium text-muted-foreground">Позиция {idx + 1}</span>
                <button
                  onClick={() => removeItem(idx)}
                  className="text-muted-foreground hover:text-destructive"
                  title="Удалить позицию"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
              <Input
                placeholder="Название товара или услуги, например: BAYRAMIX Baytera 25кг"
                value={item.productName}
                onChange={(e) => updateItem(idx, 'productName', e.target.value)}
              />
              <div className="grid grid-cols-3 gap-2">
                <Input
                  label="Кол-во"
                  type="number"
                  value={item.quantity}
                  onChange={(e) => updateItem(idx, 'quantity', parseFloat(e.target.value) || 0)}
                />
                <Input
                  label="Ед. изм."
                  value={item.unit}
                  onChange={(e) => updateItem(idx, 'unit', e.target.value)}
                  placeholder="кг"
                />
                <Input
                  label="Цена, ₽"
                  type="number"
                  value={item.price}
                  onChange={(e) => updateItem(idx, 'price', parseFloat(e.target.value) || 0)}
                />
              </div>
              <div className="text-right text-sm font-medium text-primary">
                Сумма: {formatCurrency(item.quantity * item.price)}
              </div>
            </div>
          ))}

          {items.length === 0 && (
            <p className="text-sm text-muted-foreground text-center py-4">
              Нет позиций. Нажмите «Добавить строку» выше.
            </p>
          )}
        </CardContent>
      </Card>

      {/* Step 3 — Totals */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Шаг 3 — Итоговая сумма</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <div className="flex justify-between text-sm">
            <span className="text-muted-foreground">Подытог</span>
            <span>{formatCurrency(subtotal)}</span>
          </div>
          <div className="flex items-center justify-between gap-3">
            <span className="text-sm text-muted-foreground">Скидка, ₽</span>
            <Input
              className="w-32 text-right"
              type="number"
              value={discount}
              onChange={(e) => setDiscount(e.target.value)}
              placeholder="0"
            />
          </div>
          <div className="flex justify-between font-bold border-t border-border pt-2">
            <span>К оплате</span>
            <span className="text-primary text-lg">{formatCurrency(total)}</span>
          </div>
        </CardContent>
      </Card>

      <Textarea
        label="Примечания (необязательно)"
        value={notes}
        onChange={(e) => setNotes(e.target.value)}
        placeholder="Условия оплаты, срок выполнения, особые договорённости..."
        rows={3}
      />

      {error && (
        <p className="text-sm text-destructive rounded-md bg-destructive/10 px-3 py-2">{error}</p>
      )}

      <div className="flex gap-2 pb-4">
        <Button variant="outline" className="flex-1" onClick={onCancel} disabled={saving}>
          Отмена
        </Button>
        <Button className="flex-1" onClick={handleSave} disabled={saving}>
          {saving ? 'Сохранение...' : 'Сохранить накладную'}
        </Button>
      </div>
    </div>
  )
}
