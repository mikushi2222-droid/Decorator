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
        { name: 'DECORAZZA Stucco Veneziano', unit: 'кг', price: 980, coverage: 0.35, category: 'DECORAZZA', description: 'Венецианская штукатурка, эффект полированного мрамора' },
        { name: 'DECORAZZA Art Beton', unit: 'кг', price: 720, coverage: 0.8, category: 'DECORAZZA', description: 'Эффект декоративного бетона, стиль лофт' },
        { name: 'DECORAZZA Travertino Naturale', unit: 'кг', price: 540, coverage: 1.2, category: 'DECORAZZA', description: 'Имитация натурального травертина' },
        { name: 'DECORAZZA Romano', unit: 'кг', price: 420, coverage: 2.5, category: 'DECORAZZA', description: 'Фактурная штукатурка для фасадов и интерьеров' },
        { name: 'DECORAZZA Rustic', unit: 'кг', price: 380, coverage: 3.0, category: 'DECORAZZA', description: 'Грубая фактура, вид натурального камня' },
        { name: 'DECORAZZA Barilievo', unit: 'кг', price: 580, coverage: 1.8, category: 'DECORAZZA', description: 'Рельефная штукатурка с объёмными узорами' },
        { name: 'BAYRAMIX Mineral', unit: 'кг', price: 220, coverage: 3.2, category: 'BAYRAMIX', description: 'Минеральная фасадная штукатурка' },
        { name: 'BAYRAMIX Baytera (Короед)', unit: 'кг', price: 260, coverage: 3.5, category: 'BAYRAMIX', description: 'Фактурная штукатурка типа короед' },
        { name: 'BAYRAMIX Gravol (Камешковая)', unit: 'кг', price: 240, coverage: 2.8, category: 'BAYRAMIX', description: 'Зернистая штукатурка, тип камешковая' },
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
