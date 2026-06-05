import { useState, useEffect } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Dialog } from '@/components/ui/dialog'
import { Settings as SettingsIcon, Plus, Trash2, Package, Hammer, Store, Check } from 'lucide-react'
import type { Product, LaborRate } from '@/types'

function StoreSettingsSection() {
  const settings = useLiveQuery(() => db.settings.toArray().then((s) => s[0]))
  const [saved, setSaved] = useState(false)

  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const [phone, setPhone] = useState('')
  const [inn, setInn] = useState('')

  useEffect(() => {
    if (settings) {
      setName(settings.name || '')
      setAddress(settings.address || '')
      setPhone(settings.phone || '')
      setInn(settings.inn || '')
    }
  }, [settings])

  const save = async () => {
    if (settings?.id) {
      await db.settings.update(settings.id, { name, address, phone, inn })
    } else {
      await db.settings.add({ name, address, phone, inn, logo: '' })
    }
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <Card>
      <CardHeader>
        <CardTitle className="text-base flex items-center gap-2">
          <Store className="h-4 w-4" /> Реквизиты магазина
        </CardTitle>
      </CardHeader>
      <CardContent className="space-y-3">
        <Input label="Название" value={name} onChange={(e) => setName(e.target.value)} />
        <Input label="Адрес" value={address} onChange={(e) => setAddress(e.target.value)} />
        <Input label="Телефон" value={phone} onChange={(e) => setPhone(e.target.value)} />
        <Input label="ИНН" value={inn} onChange={(e) => setInn(e.target.value)} />
        <Button className="w-full" onClick={save} variant={saved ? 'secondary' : 'default'}>
          {saved ? <><Check className="h-4 w-4" /> Сохранено</> : 'Сохранить'}
        </Button>
      </CardContent>
    </Card>
  )
}

function ProductsSection() {
  const products = useLiveQuery(() => db.products.toArray(), [])
  const [showDialog, setShowDialog] = useState(false)
  const [name, setName] = useState('')
  const [unit, setUnit] = useState('кг')
  const [price, setPrice] = useState('')
  const [coverage, setCoverage] = useState('')
  const [category, setCategory] = useState('')

  const save = async () => {
    if (!name || !price) return
    await db.products.add({
      name, unit,
      price: parseFloat(price) || 0,
      coverage: parseFloat(coverage) || 0,
      category,
      description: '',
    })
    setShowDialog(false)
    setName(''); setPrice(''); setCoverage(''); setCategory('')
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Package className="h-4 w-4" /> Каталог товаров
            </CardTitle>
            <button onClick={() => setShowDialog(true)} className="flex items-center gap-1 text-sm text-primary hover:underline">
              <Plus className="h-3.5 w-3.5" /> Добавить
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {(products || []).length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">Товаров нет</p>
          ) : (
            (products || []).map((p) => (
              <div key={p.id} className="flex items-center justify-between rounded-md border border-border px-3 py-2">
                <div className="min-w-0">
                  <p className="text-sm font-medium truncate">{p.name}</p>
                  <p className="text-xs text-muted-foreground">
                    {formatCurrency(p.price)}/{p.unit} · {p.coverage} {p.unit}/м²
                  </p>
                </div>
                <button
                  onClick={() => p.id && db.products.delete(p.id)}
                  className="ml-2 text-muted-foreground hover:text-destructive shrink-0"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onClose={() => setShowDialog(false)} title="Новый товар">
        <div className="space-y-3">
          <Input label="Название" value={name} onChange={(e) => setName(e.target.value)} placeholder="Штукатурка..." />
          <div className="grid grid-cols-2 gap-2">
            <Input label="Ед. измерения" value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="кг" />
            <Input label="Цена за ед." type="number" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="0" />
          </div>
          <Input label="Расход (ед./м²)" type="number" value={coverage} onChange={(e) => setCoverage(e.target.value)} placeholder="3.5" />
          <Input label="Категория" value={category} onChange={(e) => setCategory(e.target.value)} placeholder="Фактурные" />
          <div className="flex gap-2 pt-1">
            <Button variant="outline" className="flex-1" onClick={() => setShowDialog(false)}>Отмена</Button>
            <Button className="flex-1" onClick={save}>Добавить</Button>
          </div>
        </div>
      </Dialog>
    </>
  )
}

function LaborSection() {
  const rates = useLiveQuery(() => db.laborRates.toArray(), [])
  const [showDialog, setShowDialog] = useState(false)
  const [name, setName] = useState('')
  const [price, setPrice] = useState('')
  const [unit, setUnit] = useState('м²')

  const save = async () => {
    if (!name || !price) return
    await db.laborRates.add({ name, pricePerSqm: parseFloat(price) || 0, unit })
    setShowDialog(false)
    setName(''); setPrice('')
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Hammer className="h-4 w-4" /> Ставки работ
            </CardTitle>
            <button onClick={() => setShowDialog(true)} className="flex items-center gap-1 text-sm text-primary hover:underline">
              <Plus className="h-3.5 w-3.5" /> Добавить
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-2">
          {(rates || []).map((r) => (
            <div key={r.id} className="flex items-center justify-between rounded-md border border-border px-3 py-2">
              <div>
                <p className="text-sm font-medium">{r.name}</p>
                <p className="text-xs text-muted-foreground">{formatCurrency(r.pricePerSqm)}/{r.unit}</p>
              </div>
              <button
                onClick={() => r.id && db.laborRates.delete(r.id)}
                className="ml-2 text-muted-foreground hover:text-destructive"
              >
                <Trash2 className="h-4 w-4" />
              </button>
            </div>
          ))}
        </CardContent>
      </Card>

      <Dialog open={showDialog} onClose={() => setShowDialog(false)} title="Новый вид работ">
        <div className="space-y-3">
          <Input label="Название" value={name} onChange={(e) => setName(e.target.value)} placeholder="Нанесение штукатурки..." />
          <div className="grid grid-cols-2 gap-2">
            <Input label="Ставка" type="number" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="450" />
            <Input label="Единица" value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="м²" />
          </div>
          <div className="flex gap-2 pt-1">
            <Button variant="outline" className="flex-1" onClick={() => setShowDialog(false)}>Отмена</Button>
            <Button className="flex-1" onClick={save}>Добавить</Button>
          </div>
        </div>
      </Dialog>
    </>
  )
}

export function SettingsPage() {
  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      <h1 className="text-xl font-bold flex items-center gap-2">
        <SettingsIcon className="h-5 w-5 text-primary" />
        Настройки
      </h1>
      <StoreSettingsSection />
      <ProductsSection />
      <LaborSection />
    </div>
  )
}
