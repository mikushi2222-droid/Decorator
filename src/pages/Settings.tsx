import { useState, useEffect, useMemo } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Textarea } from '@/components/ui/textarea'
import { Dialog } from '@/components/ui/dialog'
import { Settings as SettingsIcon, Plus, Trash2, Package, Hammer, Store, Check, Info, AlertTriangle, Landmark, Search, X } from 'lucide-react'
import type { Product, LaborRate } from '@/types'

function StoreSettingsSection() {
  const settings = useLiveQuery(() => db.settings.toArray().then((s) => s[0]))
  const [saved, setSaved] = useState(false)

  const [name, setName] = useState('')
  const [address, setAddress] = useState('')
  const [phone, setPhone] = useState('')
  const [inn, setInn] = useState('')
  const [kpp, setKpp] = useState('')
  const [ogrn, setOgrn] = useState('')
  const [bankName, setBankName] = useState('')
  const [bankBik, setBankBik] = useState('')
  const [bankAccount, setBankAccount] = useState('')
  const [bankCorrAccount, setBankCorrAccount] = useState('')
  const [bankInn, setBankInn] = useState('')
  const [bankKpp, setBankKpp] = useState('')
  const [adText, setAdText] = useState('')

  useEffect(() => {
    if (settings) {
      setName(settings.name || '')
      setAddress(settings.address || '')
      setPhone(settings.phone || '')
      setInn(settings.inn || '')
      setKpp(settings.kpp || '')
      setOgrn(settings.ogrn || '')
      setBankName(settings.bankName || '')
      setBankBik(settings.bankBik || '')
      setBankAccount(settings.bankAccount || '')
      setBankCorrAccount(settings.bankCorrAccount || '')
      setBankInn(settings.bankInn || '')
      setBankKpp(settings.bankKpp || '')
      setAdText(settings.adText || '')
    }
  }, [settings])

  const save = async () => {
    const data = { name, address, phone, inn, kpp, ogrn, logo: settings?.logo || '', bankName, bankBik, bankAccount, bankCorrAccount, bankInn, bankKpp, adText }
    if (settings?.id) {
      await db.settings.update(settings.id, data)
    } else {
      await db.settings.add(data)
    }
    setSaved(true)
    setTimeout(() => setSaved(false), 2000)
  }

  return (
    <div className="space-y-3">
      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Store className="h-4 w-4" /> Реквизиты организации
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex items-start gap-2 rounded-md bg-muted/60 px-3 py-2.5 text-xs text-muted-foreground">
            <Info className="h-3.5 w-3.5 shrink-0 mt-0.5 text-primary" />
            <span>Эти данные печатаются на каждой накладной. Заполните один раз — потом они подставляются автоматически.</span>
          </div>
          <Input label="Наименование организации" value={name} onChange={(e) => setName(e.target.value)} placeholder='ООО "АКЦЕНТ"' />
          <Input label="Адрес" value={address} onChange={(e) => setAddress(e.target.value)} placeholder="г. Санкт-Петербург, ул. Примерная, 1" />
          <Input label="Телефон" value={phone} onChange={(e) => setPhone(e.target.value)} placeholder="+7 (812) 000-00-00" />
          <div className="grid grid-cols-2 gap-2">
            <Input label="ИНН" value={inn} onChange={(e) => setInn(e.target.value)} placeholder="7814860953" />
            <Input label="КПП" value={kpp} onChange={(e) => setKpp(e.target.value)} placeholder="781401001" />
          </div>
          <Input label="ОГРН" value={ogrn} onChange={(e) => setOgrn(e.target.value)} placeholder="1267800014206" />
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base flex items-center gap-2">
            <Landmark className="h-4 w-4" /> Банковские реквизиты
          </CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground">Отображаются внизу каждой накладной — для оплаты по безналу.</p>
          <Input label="Наименование банка" value={bankName} onChange={(e) => setBankName(e.target.value)} placeholder="СЕВЕРО-ЗАПАДНЫЙ БАНК ПАО СБЕРБАНК" />
          <div className="grid grid-cols-2 gap-2">
            <Input label="БИК" value={bankBik} onChange={(e) => setBankBik(e.target.value)} placeholder="044030653" />
            <Input label="ИНН банка" value={bankInn} onChange={(e) => setBankInn(e.target.value)} placeholder="7707083893" />
          </div>
          <Input label="Расчётный счёт" value={bankAccount} onChange={(e) => setBankAccount(e.target.value)} placeholder="40702810555710020199" />
          <div className="grid grid-cols-2 gap-2">
            <Input label="Корр. счёт" value={bankCorrAccount} onChange={(e) => setBankCorrAccount(e.target.value)} placeholder="30101810500000000653" />
            <Input label="КПП банка" value={bankKpp} onChange={(e) => setBankKpp(e.target.value)} placeholder="784243001" />
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle className="text-base">Реклама на накладных</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <p className="text-xs text-muted-foreground">Короткий текст — печатается внизу каждой накладной как мини-реклама.</p>
          <Textarea
            value={adText}
            onChange={(e) => setAdText(e.target.value)}
            placeholder="Барельефы · Скалы · Травертин · Шёлк · Обучение и мастер-классы"
            rows={2}
          />
        </CardContent>
      </Card>

      <Button className="w-full" onClick={save} variant={saved ? 'secondary' : 'default'}>
        {saved ? <><Check className="h-4 w-4" /> Сохранено</> : 'Сохранить реквизиты'}
      </Button>
    </div>
  )
}

function ProductsSection() {
  const products = useLiveQuery(() => db.products.toArray(), [])
  const [showDialog, setShowDialog] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<Product | null>(null)
  const [search, setSearch] = useState('')
  const [activeCategory, setActiveCategory] = useState<string>('Все')
  const [name, setName] = useState('')
  const [unit, setUnit] = useState('кг')
  const [price, setPrice] = useState('')
  const [coverage, setCoverage] = useState('')
  const [category, setCategory] = useState('')
  const [saveError, setSaveError] = useState('')

  const categories = useMemo(() => {
    const cats = Array.from(new Set((products || []).map((p) => p.category).filter(Boolean))).sort()
    return ['Все', ...cats]
  }, [products])

  const filtered = useMemo(() => {
    const all = products || []
    const q = search.trim().toLowerCase()
    return all.filter((p) => {
      const matchCat = activeCategory === 'Все' || p.category === activeCategory
      const matchSearch = !q || p.name.toLowerCase().includes(q) || p.description?.toLowerCase().includes(q)
      return matchCat && matchSearch
    })
  }, [products, search, activeCategory])

  const save = async () => {
    const parsedPrice = parseFloat(price)
    if (!name.trim()) { setSaveError('Укажите название товара'); return }
    if (!parsedPrice || parsedPrice <= 0) { setSaveError('Укажите цену — она должна быть больше нуля'); return }
    setSaveError('')
    try {
      await db.products.add({
        name: name.trim(), unit,
        price: parsedPrice,
        coverage: parseFloat(coverage) || 0,
        category,
        description: '',
      })
      setShowDialog(false)
      setName(''); setPrice(''); setCoverage(''); setCategory('')
    } catch {
      setSaveError('Ошибка сохранения. Попробуйте ещё раз.')
    }
  }

  const confirmDelete = async () => {
    if (deleteTarget?.id) {
      await db.products.delete(deleteTarget.id)
    }
    setDeleteTarget(null)
  }

  return (
    <>
      <Card>
        <CardHeader>
          <div className="flex items-center justify-between">
            <CardTitle className="text-base flex items-center gap-2">
              <Package className="h-4 w-4" /> Каталог товаров
              {products && <span className="text-xs font-normal text-muted-foreground">({products.length} позиций)</span>}
            </CardTitle>
            <button onClick={() => setShowDialog(true)} className="flex items-center gap-1 text-sm text-primary hover:underline">
              <Plus className="h-3.5 w-3.5" /> Добавить
            </button>
          </div>
        </CardHeader>
        <CardContent className="space-y-3">
          {/* Search */}
          <div className="relative">
            <Search className="absolute left-2.5 top-1/2 -translate-y-1/2 h-4 w-4 text-muted-foreground pointer-events-none" />
            <input
              type="text"
              value={search}
              onChange={(e) => setSearch(e.target.value)}
              placeholder="Поиск по названию или описанию…"
              className="w-full rounded-md border border-input bg-background pl-8 pr-8 py-2 text-sm outline-none focus:ring-2 focus:ring-ring"
            />
            {search && (
              <button
                onClick={() => setSearch('')}
                className="absolute right-2.5 top-1/2 -translate-y-1/2 text-muted-foreground hover:text-foreground"
              >
                <X className="h-3.5 w-3.5" />
              </button>
            )}
          </div>

          {/* Category filter */}
          <div className="flex flex-wrap gap-1.5">
            {categories.map((cat) => (
              <button
                key={cat}
                onClick={() => setActiveCategory(cat)}
                className={`rounded-full px-2.5 py-0.5 text-xs font-medium transition-colors ${
                  activeCategory === cat
                    ? 'bg-primary text-primary-foreground'
                    : 'bg-muted text-muted-foreground hover:bg-accent hover:text-accent-foreground'
                }`}
              >
                {cat}
              </button>
            ))}
          </div>

          {/* Results count */}
          {search || activeCategory !== 'Все' ? (
            <p className="text-xs text-muted-foreground">
              {filtered.length === 0 ? 'Ничего не найдено' : `Найдено: ${filtered.length}`}
            </p>
          ) : null}

          {/* Product list */}
          {filtered.length === 0 && !search && activeCategory === 'Все' ? (
            <p className="text-sm text-muted-foreground text-center py-4">
              Товаров нет. Нажмите «Добавить» чтобы внести первый товар.
            </p>
          ) : filtered.length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">По вашему запросу ничего не найдено.</p>
          ) : (
            <div className="max-h-96 overflow-y-auto space-y-1 pr-0.5">
              {filtered.map((p) => (
                <div key={p.id} className="flex items-center justify-between rounded-md border border-border px-3 py-2">
                  <div className="min-w-0">
                    <p className="text-sm font-medium truncate">{p.name}</p>
                    <p className="text-xs text-muted-foreground">
                      {formatCurrency(p.price)}/{p.unit}
                      {p.coverage > 0 ? ` · расход ${p.coverage} ${p.unit}/м²` : ''}
                      {p.category ? ` · ${p.category}` : ''}
                    </p>
                    {p.description && (
                      <p className="text-xs text-muted-foreground/70 truncate">{p.description}</p>
                    )}
                  </div>
                  <button
                    onClick={() => setDeleteTarget(p)}
                    className="ml-2 text-muted-foreground hover:text-destructive shrink-0"
                    title="Удалить товар"
                  >
                    <Trash2 className="h-4 w-4" />
                  </button>
                </div>
              ))}
            </div>
          )}
        </CardContent>
      </Card>

      {/* Add product dialog */}
      <Dialog open={showDialog} onClose={() => { setShowDialog(false); setSaveError('') }} title="Добавить товар в каталог">
        <div className="space-y-3">
          <Input label="Название" value={name} onChange={(e) => setName(e.target.value)} placeholder="Например: DECORAZZA Romano 25кг" />
          <div className="grid grid-cols-2 gap-2">
            <Input label="Ед. измерения" value={unit} onChange={(e) => setUnit(e.target.value)} placeholder="кг" />
            <Input label="Цена за ед., ₽" type="number" value={price} onChange={(e) => setPrice(e.target.value)} placeholder="0" />
          </div>
          <Input
            label="Расход на 1 м² (необязательно)"
            type="number"
            value={coverage}
            onChange={(e) => setCoverage(e.target.value)}
            placeholder="3.5"
            hint="Кг (или л) на 1 м² — указано в инструкции на упаковке"
          />
          <Input label="Категория (необязательно)" value={category} onChange={(e) => setCategory(e.target.value)} placeholder="DECORAZZA" />
          {saveError && <p className="text-xs text-destructive">{saveError}</p>}
          <div className="flex gap-2 pt-1">
            <Button variant="outline" className="flex-1" onClick={() => { setShowDialog(false); setSaveError('') }}>Отмена</Button>
            <Button className="flex-1" onClick={save}>Добавить</Button>
          </div>
        </div>
      </Dialog>

      {/* Delete confirmation dialog */}
      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} title="Удалить товар?">
        <div className="space-y-4">
          <div className="flex items-start gap-3 rounded-md bg-destructive/10 px-3 py-3">
            <AlertTriangle className="h-5 w-5 text-destructive shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">«{deleteTarget?.name}»</p>
              <p className="text-sm text-muted-foreground mt-1">
                Товар будет удалён из каталога. Уже созданные накладные не изменятся.
              </p>
            </div>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => setDeleteTarget(null)}>Отмена</Button>
            <Button variant="destructive" className="flex-1" onClick={confirmDelete}>Удалить</Button>
          </div>
        </div>
      </Dialog>
    </>
  )
}

function LaborSection() {
  const rates = useLiveQuery(() => db.laborRates.toArray(), [])
  const [showDialog, setShowDialog] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<LaborRate | null>(null)
  const [name, setName] = useState('')
  const [price, setPrice] = useState('')
  const [unit, setUnit] = useState('м²')
  const [saveError, setSaveError] = useState('')

  const save = async () => {
    const parsedPrice = parseFloat(price)
    if (!name.trim()) { setSaveError('Укажите название вида работ'); return }
    if (!parsedPrice || parsedPrice <= 0) { setSaveError('Укажите ставку — она должна быть больше нуля'); return }
    setSaveError('')
    try {
      await db.laborRates.add({ name: name.trim(), pricePerSqm: parsedPrice, unit })
      setShowDialog(false)
      setName(''); setPrice('')
    } catch {
      setSaveError('Ошибка сохранения. Попробуйте ещё раз.')
    }
  }

  const confirmDelete = async () => {
    if (deleteTarget?.id) {
      await db.laborRates.delete(deleteTarget.id)
    }
    setDeleteTarget(null)
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
          <p className="text-xs text-muted-foreground">
            Ставки используются в калькуляторе при расчёте стоимости работ.
          </p>
          {(rates || []).length === 0 ? (
            <p className="text-sm text-muted-foreground text-center py-4">
              Ставок нет. Нажмите «Добавить» чтобы внести первую ставку.
            </p>
          ) : (
            (rates || []).map((r) => (
              <div key={r.id} className="flex items-center justify-between rounded-md border border-border px-3 py-2">
                <div>
                  <p className="text-sm font-medium">{r.name}</p>
                  <p className="text-xs text-muted-foreground">{formatCurrency(r.pricePerSqm)} за {r.unit}</p>
                </div>
                <button
                  onClick={() => setDeleteTarget(r)}
                  className="ml-2 text-muted-foreground hover:text-destructive"
                  title="Удалить ставку"
                >
                  <Trash2 className="h-4 w-4" />
                </button>
              </div>
            ))
          )}
        </CardContent>
      </Card>

      {/* Add labor dialog */}
      <Dialog open={showDialog} onClose={() => { setShowDialog(false); setSaveError('') }} title="Добавить вид работ">
        <div className="space-y-3">
          <Input
            label="Название"
            value={name}
            onChange={(e) => setName(e.target.value)}
            placeholder="Например: Нанесение декоративной штукатурки"
          />
          <div className="grid grid-cols-2 gap-2">
            <Input
              label="Ставка, ₽"
              type="number"
              value={price}
              onChange={(e) => setPrice(e.target.value)}
              placeholder="450"
              hint="Цена за единицу"
            />
            <Input
              label="Единица"
              value={unit}
              onChange={(e) => setUnit(e.target.value)}
              placeholder="м²"
            />
          </div>
          {saveError && <p className="text-xs text-destructive">{saveError}</p>}
          <div className="flex gap-2 pt-1">
            <Button variant="outline" className="flex-1" onClick={() => { setShowDialog(false); setSaveError('') }}>Отмена</Button>
            <Button className="flex-1" onClick={save}>Добавить</Button>
          </div>
        </div>
      </Dialog>

      {/* Delete confirmation dialog */}
      <Dialog open={!!deleteTarget} onClose={() => setDeleteTarget(null)} title="Удалить вид работ?">
        <div className="space-y-4">
          <div className="flex items-start gap-3 rounded-md bg-destructive/10 px-3 py-3">
            <AlertTriangle className="h-5 w-5 text-destructive shrink-0 mt-0.5" />
            <div>
              <p className="text-sm font-medium">«{deleteTarget?.name}»</p>
              <p className="text-sm text-muted-foreground mt-1">
                Ставка будет удалена. Это не повлияет на уже созданные накладные.
              </p>
            </div>
          </div>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => setDeleteTarget(null)}>Отмена</Button>
            <Button variant="destructive" className="flex-1" onClick={confirmDelete}>Удалить</Button>
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
