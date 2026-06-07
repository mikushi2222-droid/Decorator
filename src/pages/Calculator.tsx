import { useState } from 'react'
import { useLiveQuery } from 'dexie-react-hooks'
import { db } from '@/lib/db'
import { formatCurrency, formatNumber } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Button } from '@/components/ui/button'
import { Input } from '@/components/ui/input'
import { Select } from '@/components/ui/select'
import { Badge } from '@/components/ui/badge'
import { Calculator as CalcIcon, Printer, RotateCcw, ChevronRight, Info } from 'lucide-react'
import type { CalcMode, LaborRate } from '@/types'
import { usePrint } from '@/hooks/usePrint'

type AreaMode = 'dimensions' | 'direct'

interface CalcResult {
  area: number
  materialKg: number
  materialPacks: number
  packWeight: number
  materialCost: number
  laborCost: number
  total: number
  selectedLaborRates: { rate: LaborRate; sqmCost: number }[]
}

export function CalculatorPage() {
  const products = useLiveQuery(() => db.products.toArray(), [])
  const laborRates = useLiveQuery(() => db.laborRates.toArray(), [])

  const [areaMode, setAreaMode] = useState<AreaMode>('dimensions')
  const [length, setLength] = useState('')
  const [width, setWidth] = useState('')
  const [height, setHeight] = useState('')
  const [area, setArea] = useState('')
  const [productId, setProductId] = useState('')
  const [packSize, setPackSize] = useState('25')
  const [mode, setMode] = useState<CalcMode>('both')
  const [selectedRates, setSelectedRates] = useState<number[]>([])
  const [result, setResult] = useState<CalcResult | null>(null)
  const [areaError, setAreaError] = useState('')

  const { printRef, handlePrint } = usePrint()

  const productOptions = (products || [])
    .filter((p) => p.coverage > 0)
    .map((p) => ({
      value: String(p.id),
      label: `${p.name} — ${p.coverage} кг/м²`,
    }))

  const modeOptions: { value: CalcMode; label: string }[] = [
    { value: 'both', label: 'Материал + работа (полная стоимость)' },
    { value: 'material', label: 'Только материал (без работы)' },
    { value: 'labor', label: 'Только работа (без материала)' },
  ]

  const calcArea = (): number => {
    if (areaMode === 'direct') return parseFloat(area) || 0
    const l = parseFloat(length) || 0
    const w = parseFloat(width) || 0
    const h = parseFloat(height) || 0
    if (h > 0) return (l + w) * 2 * h
    return l * w
  }

  const calculate = () => {
    const totalArea = calcArea()
    if (totalArea <= 0) {
      setAreaError('Введите площадь больше нуля')
      return
    }
    setAreaError('')

    const product = products?.find((p) => String(p.id) === productId)
    const pack = parseFloat(packSize) || 25

    let materialKg = 0
    let materialPacks = 0
    let materialCost = 0

    if (mode !== 'labor' && product) {
      materialKg = totalArea * product.coverage
      materialPacks = Math.ceil(materialKg / pack)
      materialCost = materialPacks * pack * product.price
    }

    // В режиме «только материал» работы не учитываем — иначе в результате
    // показывались бы строки работ, не входящие в «Итого».
    const activeRates = mode !== 'material'
      ? (laborRates || []).filter((r) => selectedRates.includes(r.id!))
      : []
    const selectedLaborRates = activeRates.map((r) => ({
      rate: r,
      sqmCost: r.pricePerSqm * totalArea,
    }))
    const laborCost = selectedLaborRates.reduce((s, r) => s + r.sqmCost, 0)

    setResult({
      area: totalArea,
      materialKg,
      materialPacks,
      packWeight: pack,
      materialCost,
      laborCost,
      total: materialCost + laborCost,
      selectedLaborRates,
    })
  }

  const reset = () => {
    setLength(''); setWidth(''); setHeight(''); setArea('')
    setProductId(''); setResult(null); setSelectedRates([]); setAreaError('')
  }

  const toggleRate = (id: number) => {
    setSelectedRates((prev) => prev.includes(id) ? prev.filter((r) => r !== id) : [...prev, id])
  }

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <CalcIcon className="h-5 w-5 text-primary" />
          Калькулятор
        </h1>
        <button onClick={reset} className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
          <RotateCcw className="h-4 w-4" /> Сброс
        </button>
      </div>

      {/* How-to hint */}
      <div className="flex items-start gap-2 rounded-lg bg-muted/60 border border-border px-4 py-3 text-sm text-muted-foreground">
        <Info className="h-4 w-4 shrink-0 mt-0.5 text-primary" />
        <div>
          <p className="font-medium text-foreground mb-0.5">Как рассчитать стоимость:</p>
          <ol className="list-decimal list-inside space-y-0.5">
            <li>Введите размеры помещения</li>
            <li>Выберите штукатурку и фасовку</li>
            <li>Отметьте виды работ (если нужно)</li>
            <li>Нажмите «Рассчитать»</li>
          </ol>
        </div>
      </div>

      {/* Area input */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Шаг 1 — Площадь</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          <div className="flex rounded-lg border border-border overflow-hidden text-sm">
            <button
              className={`flex-1 py-2.5 transition-colors ${areaMode === 'dimensions' ? 'bg-primary text-primary-foreground' : 'hover:bg-accent'}`}
              onClick={() => setAreaMode('dimensions')}
            >
              По размерам
            </button>
            <button
              className={`flex-1 py-2.5 transition-colors ${areaMode === 'direct' ? 'bg-primary text-primary-foreground' : 'hover:bg-accent'}`}
              onClick={() => setAreaMode('direct')}
            >
              Ввести площадь
            </button>
          </div>

          {areaMode === 'dimensions' ? (
            <div className="space-y-2">
              <p className="text-xs text-muted-foreground">Введите длину и ширину комнаты в метрах.</p>
              <div className="grid grid-cols-2 gap-2">
                <Input label="Длина, м" type="number" value={length} onChange={(e) => setLength(e.target.value)} placeholder="0" />
                <Input label="Ширина, м" type="number" value={width} onChange={(e) => setWidth(e.target.value)} placeholder="0" />
              </div>
              <Input
                label="Высота стен, м"
                type="number"
                value={height}
                onChange={(e) => setHeight(e.target.value)}
                placeholder="Оставьте пустым для пола/потолка"
                hint={height
                  ? `Площадь стен: (${length || '0'} + ${width || '0'}) × 2 × ${height} = ${formatNumber(calcArea())} м²`
                  : 'Для стен введите высоту потолка. Для пола или потолка — оставьте пустым.'}
              />
              {calcArea() > 0 && (
                <div className="rounded-md bg-primary/10 border border-primary/20 px-3 py-2 text-sm font-medium">
                  Расчётная площадь: {formatNumber(calcArea())} м²
                </div>
              )}
            </div>
          ) : (
            <div className="space-y-2">
              <p className="text-xs text-muted-foreground">Введите готовую площадь, если она уже известна.</p>
              <Input
                label="Площадь, м²"
                type="number"
                value={area}
                onChange={(e) => setArea(e.target.value)}
                placeholder="0"
              />
            </div>
          )}
        </CardContent>
      </Card>

      {/* Mode */}
      <Card>
        <CardHeader>
          <CardTitle className="text-base">Шаг 2 — Что считаем</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <Select
            options={modeOptions}
            value={mode}
            onChange={(e) => setMode(e.target.value as CalcMode)}
          />
          <p className="text-xs text-muted-foreground">
            {mode === 'both' && 'Посчитает и стоимость материала, и стоимость работ.'}
            {mode === 'material' && 'Только материал — сколько штукатурки нужно купить.'}
            {mode === 'labor' && 'Только работа — сколько стоит нанесение без материала.'}
          </p>
        </CardContent>
      </Card>

      {/* Material */}
      {mode !== 'labor' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Шаг 3 — Материал</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3">
            <Select
              label="Вид штукатурки"
              options={productOptions}
              value={productId}
              onChange={(e) => setProductId(e.target.value)}
              placeholder="— Выберите из каталога —"
            />
            {!productId && (
              <p className="text-xs text-muted-foreground">
                Если нужного товара нет в списке — добавьте его в разделе «Настройки → Каталог товаров».
              </p>
            )}
            <Select
              label="Фасовка упаковки"
              options={[
                { value: '5', label: '5 кг' },
                { value: '10', label: '10 кг' },
                { value: '15', label: '15 кг' },
                { value: '25', label: '25 кг (стандарт)' },
                { value: '30', label: '30 кг' },
              ]}
              value={packSize}
              onChange={(e) => setPackSize(e.target.value)}
            />
          </CardContent>
        </Card>
      )}

      {/* Labor */}
      {mode !== 'material' && (laborRates || []).length > 0 && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">
              {mode === 'labor' ? 'Шаг 3 — Виды работ' : 'Шаг 4 — Виды работ'}
            </CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            <p className="text-xs text-muted-foreground">
              Отметьте галочками все работы, которые входят в смету.
            </p>
            {(laborRates || []).map((r) => (
              <label
                key={r.id}
                className={`flex items-center justify-between rounded-md border px-3 py-3 cursor-pointer transition-colors ${
                  selectedRates.includes(r.id!) ? 'border-primary bg-primary/5' : 'border-border hover:bg-accent'
                }`}
              >
                <div className="flex items-center gap-2">
                  <input
                    type="checkbox"
                    className="h-4 w-4 accent-primary"
                    checked={selectedRates.includes(r.id!)}
                    onChange={() => toggleRate(r.id!)}
                  />
                  <span className="text-sm">{r.name}</span>
                </div>
                <span className="text-sm font-medium text-muted-foreground">{formatCurrency(r.pricePerSqm)}/{r.unit}</span>
              </label>
            ))}
          </CardContent>
        </Card>
      )}

      {areaError && (
        <p className="text-sm text-destructive rounded-md bg-destructive/10 px-3 py-2">{areaError}</p>
      )}

      {/* Calculate button */}
      <Button className="w-full" size="lg" onClick={calculate}>
        Рассчитать <ChevronRight className="h-4 w-4" />
      </Button>

      {/* Result */}
      {result && (
        <div ref={printRef}>
          <Card className="border-primary/30 bg-primary/5">
            <CardHeader>
              <div className="flex items-center justify-between">
                <CardTitle className="text-base">Результат расчёта</CardTitle>
                <button
                  onClick={() => handlePrint()}
                  className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground no-print"
                >
                  <Printer className="h-4 w-4" /> Печать
                </button>
              </div>
            </CardHeader>
            <CardContent className="space-y-3">
              <div className="rounded-md bg-card border border-border divide-y divide-border text-sm">
                <div className="flex justify-between px-3 py-2">
                  <span className="text-muted-foreground">Площадь</span>
                  <span className="font-medium">{formatNumber(result.area)} м²</span>
                </div>
                {mode !== 'labor' && result.materialKg > 0 && (
                  <>
                    <div className="flex justify-between px-3 py-2">
                      <span className="text-muted-foreground">Потребность в материале</span>
                      <span className="font-medium">{formatNumber(result.materialKg)} кг</span>
                    </div>
                    <div className="flex justify-between px-3 py-2">
                      <span className="text-muted-foreground">Упаковок по {result.packWeight} кг</span>
                      <span className="font-medium">{result.materialPacks} шт.</span>
                    </div>
                    <div className="flex justify-between px-3 py-2">
                      <span className="text-muted-foreground">Стоимость материала</span>
                      <span className="font-medium">{formatCurrency(result.materialCost)}</span>
                    </div>
                  </>
                )}
                {mode !== 'labor' && !productId && result.area > 0 && (
                  <div className="px-3 py-2 text-xs text-muted-foreground italic">
                    Штукатурка не выбрана — стоимость материала не посчитана
                  </div>
                )}
                {result.selectedLaborRates.map(({ rate, sqmCost }) => (
                  <div key={rate.id} className="flex justify-between px-3 py-2">
                    <span className="text-muted-foreground">{rate.name}</span>
                    <span className="font-medium">{formatCurrency(sqmCost)}</span>
                  </div>
                ))}
                {mode !== 'material' && result.selectedLaborRates.length === 0 && (
                  <div className="px-3 py-2 text-xs text-muted-foreground italic">
                    Виды работ не выбраны — стоимость работ не посчитана
                  </div>
                )}
              </div>

              <div className="flex items-center justify-between rounded-lg bg-primary px-4 py-3">
                <span className="font-semibold text-primary-foreground">Итого</span>
                <span className="text-xl font-bold text-primary-foreground">{formatCurrency(result.total)}</span>
              </div>

              {result.materialCost > 0 && result.laborCost > 0 && (
                <div className="flex gap-2 text-xs">
                  <Badge variant="secondary">Материал: {formatCurrency(result.materialCost)}</Badge>
                  <Badge variant="secondary">Работа: {formatCurrency(result.laborCost)}</Badge>
                </div>
              )}
            </CardContent>
          </Card>
        </div>
      )}
    </div>
  )
}
