import Dexie, { type EntityTable } from 'dexie'
import type { Client, Invoice, Product, LaborRate, StoreSettings } from '@/types'

class DecoratorDB extends Dexie {
  clients!: EntityTable<Client, 'id'>
  invoices!: EntityTable<Invoice, 'id'>
  products!: EntityTable<Product, 'id'>
  laborRates!: EntityTable<LaborRate, 'id'>
  settings!: EntityTable<StoreSettings, 'id'>

  constructor() {
    super('DecoratorDB')
    this.version(1).stores({
      clients: '++id, name, phone, createdAt',
      invoices: '++id, number, date, clientName, status, createdAt',
      products: '++id, name, category',
      laborRates: '++id, name',
      settings: '++id',
    })
  }
}

export const db = new DecoratorDB()

async function seedIfEmpty() {
  // Транзакция гарантирует атомарность: при одновременном открытии двух вкладок
  // второй поток будет ждать завершения первого, count() внутри транзакции корректен.
  await db.transaction('rw', db.products, db.laborRates, db.settings, async () => {
    const productCount = await db.products.count()
    if (productCount === 0) {
      await db.products.bulkAdd([
        { name: 'Штукатурка декоративная "Короед" 2мм', unit: 'кг', price: 320, coverage: 3.5, category: 'Фактурные', description: 'Классическая фактура для фасадов и интерьеров' },
        { name: 'Штукатурка "Венецианская"', unit: 'кг', price: 850, coverage: 0.4, category: 'Декоративные', description: 'Имитация мрамора, полированная поверхность' },
        { name: 'Штукатурка "Травертин"', unit: 'кг', price: 490, coverage: 1.2, category: 'Декоративные', description: 'Имитация натурального камня' },
        { name: 'Штукатурка "Шуба" 2.5мм', unit: 'кг', price: 280, coverage: 4.0, category: 'Фактурные', description: 'Грубая фактурная поверхность' },
        { name: 'Штукатурка "Мокрый шёлк"', unit: 'кг', price: 720, coverage: 0.3, category: 'Перламутровые', description: 'Эффект шёлка с перламутровым блеском' },
        { name: 'Штукатурка "Камешковая" 1.5мм', unit: 'кг', price: 310, coverage: 2.8, category: 'Фактурные', description: 'Мелкая зернистая поверхность' },
        { name: 'Грунтовка адгезионная', unit: 'л', price: 180, coverage: 6.0, category: 'Расходники', description: 'Под декоративные штукатурки' },
        { name: 'Воск защитный прозрачный', unit: 'л', price: 420, coverage: 8.0, category: 'Расходники', description: 'Финишная защита поверхности' },
      ])
    }

    const laborCount = await db.laborRates.count()
    if (laborCount === 0) {
      await db.laborRates.bulkAdd([
        { name: 'Подготовка поверхности (шпаклёвка)', pricePerSqm: 250, unit: 'м²' },
        { name: 'Нанесение грунтовки', pricePerSqm: 80, unit: 'м²' },
        { name: 'Нанесение декоративной штукатурки', pricePerSqm: 450, unit: 'м²' },
        { name: 'Венецианская штукатурка (2–3 слоя)', pricePerSqm: 1200, unit: 'м²' },
        { name: 'Покрытие воском/лаком', pricePerSqm: 150, unit: 'м²' },
      ])
    }

    const settingsCount = await db.settings.count()
    if (settingsCount === 0) {
      await db.settings.add({
        name: 'Магазин Декоратор',
        address: 'г. Москва, ул. Примерная, 1',
        phone: '+7 (999) 000-00-00',
        inn: '',
        logo: '',
      })
    }
  })
}

seedIfEmpty().catch(console.error)
