import { useRef } from 'react'
import { useReactToPrint } from 'react-to-print'

export function usePrint() {
  const printRef = useRef<HTMLDivElement>(null)
  const handlePrint = useReactToPrint({ contentRef: printRef })
  return { printRef, handlePrint }
}
