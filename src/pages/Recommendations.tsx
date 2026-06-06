import { useState } from 'react'
import { PLASTERS, SURFACES, ROOMS, STYLES } from '@/lib/plasters'
import { formatCurrency } from '@/lib/utils'
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/card'
import { Badge } from '@/components/ui/badge'
import { Button } from '@/components/ui/button'
import { Sparkles, Clock, Star, ChevronDown, ChevronUp, RotateCcw, AlertCircle } from 'lucide-react'
import type { PlasterType } from '@/types'

type Step = 'surface' | 'room' | 'style' | 'results'

function FilterChip({ label, active, onClick }: { label: string; active: boolean; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className={`rounded-full border px-3 py-2 text-sm transition-colors ${
        active
          ? 'border-primary bg-primary text-primary-foreground'
          : 'border-border hover:border-primary/50 hover:bg-accent'
      }`}
    >
      {label}
    </button>
  )
}

function PlasterCard({ plaster }: { plaster: PlasterType }) {
  const [expanded, setExpanded] = useState(false)
  const pricePerSqm = plaster.coverageKgPerSqm * plaster.pricePerKg

  return (
    <Card className="overflow-hidden">
      <CardContent className="p-4 space-y-3">
        <div className="flex items-start justify-between gap-2">
          <div>
            <h3 className="font-semibold">{plaster.name}</h3>
            <p className="text-xs text-muted-foreground">{plaster.brand}</p>
          </div>
          <div className="text-right shrink-0">
            <p className="font-bold text-primary">{formatCurrency(pricePerSqm)}/м²</p>
            <p className="text-xs text-muted-foreground">{formatCurrency(plaster.pricePerKg)}/кг</p>
          </div>
        </div>

        <p className="text-sm text-muted-foreground">{plaster.description}</p>

        <div className="flex flex-wrap gap-1">
          {plaster.style.map((s) => (
            <Badge key={s} variant="secondary" className="text-xs">{s}</Badge>
          ))}
        </div>

        <div className="grid grid-cols-2 gap-2 text-xs rounded-md bg-muted/50 p-2">
          <div>
            <span className="text-muted-foreground">Расход материала</span>
            <p className="font-medium">{plaster.coverageKgPerSqm} кг/м²</p>
          </div>
          <div>
            <span className="text-muted-foreground">Время высыхания</span>
            <p className="font-medium flex items-center gap-1">
              <Clock className="h-3 w-3" /> {plaster.dryingTime}
            </p>
          </div>
        </div>

        {expanded && (
          <div className="space-y-2">
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">Подходит для поверхностей</p>
              <div className="flex flex-wrap gap-1">
                {plaster.surfaces.map((s) => <Badge key={s} variant="outline" className="text-xs">{s}</Badge>)}
              </div>
            </div>
            <div>
              <p className="text-xs font-medium text-muted-foreground mb-1">Преимущества</p>
              <ul className="space-y-0.5">
                {plaster.pros.map((pro) => (
                  <li key={pro} className="flex items-center gap-1.5 text-xs">
                    <Star className="h-3 w-3 text-primary shrink-0" />
                    {pro}
                  </li>
                ))}
              </ul>
            </div>
          </div>
        )}

        <button
          onClick={() => setExpanded((e) => !e)}
          className="flex items-center gap-1 text-xs text-primary hover:underline"
        >
          {expanded ? <><ChevronUp className="h-3 w-3" /> Скрыть</> : <><ChevronDown className="h-3 w-3" /> Подробнее</>}
        </button>
      </CardContent>
    </Card>
  )
}

export function RecommendationsPage() {
  const [step, setStep] = useState<Step>('surface')
  const [surface, setSurface] = useState('')
  const [room, setRoom] = useState('')
  const [style, setStyle] = useState('')
  const [results, setResults] = useState<PlasterType[]>([])
  const [noExactMatch, setNoExactMatch] = useState(false)

  const [browseMode, setBrowseMode] = useState(false)

  const runFilter = () => {
    let filtered = PLASTERS
    if (surface) filtered = filtered.filter((p) => p.surfaces.includes(surface))
    if (room) filtered = filtered.filter((p) => p.rooms.includes(room))
    if (style) filtered = filtered.filter((p) => p.style.includes(style))
    const fallback = filtered.length === 0
    if (fallback) filtered = PLASTERS
    setNoExactMatch(fallback)
    setResults(filtered)
    setStep('results')
  }

  const reset = () => {
    setSurface(''); setRoom(''); setStyle('')
    setStep('surface'); setResults([]); setNoExactMatch(false)
  }

  if (browseMode) {
    return (
      <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-xl font-bold flex items-center gap-2">
            <Sparkles className="h-5 w-5 text-primary" />
            Весь каталог
          </h1>
          <button onClick={() => setBrowseMode(false)} className="text-sm text-primary hover:underline">
            ← Мастер подбора
          </button>
        </div>
        <p className="text-sm text-muted-foreground">Все доступные штукатурки с описанием и ценами.</p>
        <div className="space-y-3">
          {PLASTERS.map((p) => <PlasterCard key={p.id} plaster={p} />)}
        </div>
      </div>
    )
  }

  const stepIndex = (['surface', 'room', 'style', 'results'] as Step[]).indexOf(step)

  return (
    <div className="mx-auto max-w-lg px-4 py-5 space-y-4">
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-bold flex items-center gap-2">
          <Sparkles className="h-5 w-5 text-primary" />
          Подбор штукатурки
        </h1>
        {step !== 'surface' && (
          <button onClick={reset} className="flex items-center gap-1 text-sm text-muted-foreground hover:text-foreground">
            <RotateCcw className="h-4 w-4" /> Сначала
          </button>
        )}
      </div>

      {/* Hint for step 1 */}
      {step === 'surface' && (
        <div className="rounded-lg bg-muted/60 border border-border px-4 py-3 text-sm text-muted-foreground">
          Ответьте на 3 вопроса — программа подберёт подходящие варианты штукатурки.
          Можно пропустить любой вопрос, нажав «Далее».
        </div>
      )}

      {/* Progress */}
      <div className="space-y-1">
        <div className="flex gap-1">
          {(['surface', 'room', 'style', 'results'] as Step[]).map((s, i) => (
            <div
              key={s}
              className={`h-1.5 flex-1 rounded-full transition-colors ${
                stepIndex >= i ? 'bg-primary' : 'bg-muted'
              }`}
            />
          ))}
        </div>
        <p className="text-xs text-muted-foreground text-right">
          {stepIndex < 3 ? `Шаг ${stepIndex + 1} из 3` : 'Результаты'}
        </p>
      </div>

      {step === 'surface' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Шаг 1 — Тип поверхности</CardTitle>
            <p className="text-sm text-muted-foreground">Из чего сделана стена (или пол/потолок), которую нужно отделать?</p>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex flex-wrap gap-2">
              {SURFACES.map((s) => (
                <FilterChip key={s} label={s} active={surface === s} onClick={() => setSurface(s === surface ? '' : s)} />
              ))}
            </div>
            {!surface && (
              <p className="text-xs text-muted-foreground">Не знаете — нажмите «Далее», пропустим этот вопрос.</p>
            )}
            <Button className="w-full" onClick={() => setStep('room')}>
              Далее →
            </Button>
          </CardContent>
        </Card>
      )}

      {step === 'room' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Шаг 2 — Помещение / объект</CardTitle>
            <p className="text-sm text-muted-foreground">Где будет применяться штукатурка?</p>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex flex-wrap gap-2">
              {ROOMS.map((r) => (
                <FilterChip key={r} label={r} active={room === r} onClick={() => setRoom(r === room ? '' : r)} />
              ))}
            </div>
            {!room && (
              <p className="text-xs text-muted-foreground">Не знаете — нажмите «Далее», пропустим этот вопрос.</p>
            )}
            <div className="flex gap-2">
              <Button variant="outline" className="flex-1" onClick={() => setStep('surface')}>← Назад</Button>
              <Button className="flex-1" onClick={() => setStep('style')}>Далее →</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {step === 'style' && (
        <Card>
          <CardHeader>
            <CardTitle className="text-base">Шаг 3 — Стиль интерьера</CardTitle>
            <p className="text-sm text-muted-foreground">Какой стиль предпочитает клиент?</p>
          </CardHeader>
          <CardContent className="space-y-3">
            <div className="flex flex-wrap gap-2">
              {STYLES.map((s) => (
                <FilterChip key={s} label={s} active={style === s} onClick={() => setStyle(s === style ? '' : s)} />
              ))}
            </div>
            {!style && (
              <p className="text-xs text-muted-foreground">Не знаете — нажмите «Показать результаты».</p>
            )}
            <div className="flex gap-2">
              <Button variant="outline" className="flex-1" onClick={() => setStep('room')}>← Назад</Button>
              <Button className="flex-1" onClick={runFilter}>Показать результаты</Button>
            </div>
          </CardContent>
        </Card>
      )}

      {step === 'results' && (
        <div className="space-y-3">
          {noExactMatch ? (
            <div className="flex items-start gap-2 rounded-lg bg-amber-50 border border-amber-200 px-3 py-2.5 text-sm text-amber-800">
              <AlertCircle className="h-4 w-4 shrink-0 mt-0.5" />
              <span>По выбранным критериям совпадений не найдено. Показываем весь каталог — выберите подходящий вариант сами.</span>
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">
              Найдено подходящих вариантов: <strong>{results.length}</strong>
            </p>
          )}

          {/* Applied filters */}
          {(surface || room || style) && (
            <div className="flex flex-wrap gap-1">
              {surface && <Badge variant="secondary">Поверхность: {surface}</Badge>}
              {room && <Badge variant="secondary">Помещение: {room}</Badge>}
              {style && <Badge variant="secondary">Стиль: {style}</Badge>}
            </div>
          )}

          {results.map((p) => <PlasterCard key={p.id} plaster={p} />)}

          <Button variant="outline" className="w-full" onClick={reset}>
            <RotateCcw className="h-4 w-4" /> Начать заново
          </Button>
        </div>
      )}

      {/* Browse all link */}
      {step !== 'results' && (
        <button
          onClick={() => setBrowseMode(true)}
          className="w-full text-center text-sm text-primary hover:underline py-2"
        >
          Посмотреть весь каталог →
        </button>
      )}
    </div>
  )
}
