import { BrowserRouter, Routes, Route } from 'react-router-dom'
import { Layout } from '@/components/Layout'
import { CalculatorPage } from '@/pages/Calculator'
import { InvoicesPage } from '@/pages/Invoices'
import { RecommendationsPage } from '@/pages/Recommendations'
import { SettingsPage } from '@/pages/Settings'

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<Layout />}>
          <Route index element={<CalculatorPage />} />
          <Route path="invoices" element={<InvoicesPage />} />
          <Route path="recommendations" element={<RecommendationsPage />} />
          <Route path="settings" element={<SettingsPage />} />
        </Route>
      </Routes>
    </BrowserRouter>
  )
}
