import React, { useRef, useState, useEffect } from 'react';
import { 
  PenTool, 
  Eraser, 
  RotateCcw, 
  Download, 
  Palette, 
  Highlighter, 
  Eye, 
  EyeOff,
  Sparkles
} from 'lucide-react';

export const StylusCanvasLayer: React.FC = () => {
  const canvasRef = useRef<HTMLCanvasElement | null>(null);
  const [isDrawing, setIsDrawing] = useState(false);
  const [penColor, setPenColor] = useState('#FF4700');
  const [penSize, setPenSize] = useState(3);
  const [isEraser, setIsEraser] = useState(false);
  const [isHighlighter, setIsHighlighter] = useState(false);
  const [isVisible, setIsVisible] = useState(true);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    // تنظیم ابعاد Canvas بر اساس اندازه صفحه نمایش
    const resizeCanvas = () => {
      canvas.width = canvas.parentElement?.clientWidth || window.innerWidth;
      canvas.height = canvas.parentElement?.clientHeight || window.innerHeight;
    };

    resizeCanvas();
    window.addEventListener('resize', resizeCanvas);
    return () => window.removeEventListener('resize', resizeCanvas);
  }, []);

  const startDrawing = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    setIsDrawing(true);
    const rect = canvas.getBoundingClientRect();
    const x = 'touches' in e ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = 'touches' in e ? e.touches[0].clientY - rect.top : e.clientY - rect.top;

    ctx.beginPath();
    ctx.moveTo(x, y);
  };

  const draw = (e: React.MouseEvent<HTMLCanvasElement> | React.TouchEvent<HTMLCanvasElement>) => {
    if (!isDrawing) return;
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;

    const rect = canvas.getBoundingClientRect();
    const x = 'touches' in e ? e.touches[0].clientX - rect.left : e.clientX - rect.left;
    const y = 'touches' in e ? e.touches[0].clientY - rect.top : e.clientY - rect.top;

    ctx.lineCap = 'round';
    ctx.lineJoin = 'round';

    if (isEraser) {
      ctx.globalCompositeOperation = 'destination-out';
      ctx.lineWidth = penSize * 4;
    } else if (isHighlighter) {
      ctx.globalCompositeOperation = 'source-over';
      ctx.strokeStyle = `${penColor}55`; // نیمه شفاف برای هایلایتر
      ctx.lineWidth = penSize * 5;
    } else {
      ctx.globalCompositeOperation = 'source-over';
      ctx.strokeStyle = penColor;
      ctx.lineWidth = penSize;
    }

    ctx.lineTo(x, y);
    ctx.stroke();
  };

  const stopDrawing = () => {
    setIsDrawing(false);
  };

  const handleClear = () => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext('2d');
    if (!ctx) return;
    ctx.clearRect(0, 0, canvas.width, canvas.height);
  };

  const colors = ['#FF4700', '#3B82F6', '#10B981', '#F59E0B', '#8B5CF6', '#FFFFFF'];

  return (
    <div className="relative w-full h-full flex flex-col overflow-hidden select-none">
      {/* Floating Stylus Toolbar */}
      <div className="absolute top-4 left-4 z-40 rounded-precision-md bg-canvas-elevated liquid-glass border border-border-highlight shadow-2xl p-2 flex items-center gap-2">
        <button
          onClick={() => { setIsEraser(false); setIsHighlighter(false); }}
          className={`p-1.5 rounded transition ${
            !isEraser && !isHighlighter ? 'bg-accent-primary text-white' : 'text-ink-muted hover:text-ink-primary'
          }`}
          title="قلم دستی (Pen)"
        >
          <PenTool className="w-4 h-4" />
        </button>

        <button
          onClick={() => { setIsEraser(false); setIsHighlighter(true); }}
          className={`p-1.5 rounded transition ${
            isHighlighter ? 'bg-accent-primary text-white' : 'text-ink-muted hover:text-ink-primary'
          }`}
          title="هایلایتر پاستلی (Highlighter)"
        >
          <Highlighter className="w-4 h-4" />
        </button>

        <button
          onClick={() => { setIsEraser(true); setIsHighlighter(false); }}
          className={`p-1.5 rounded transition ${
            isEraser ? 'bg-accent-primary text-white' : 'text-ink-muted hover:text-ink-primary'
          }`}
          title="پاک‌کن (Eraser)"
        >
          <Eraser className="w-4 h-4" />
        </button>

        {/* Color Palette */}
        <div className="flex items-center gap-1 border-r border-border-subtle pr-2 mr-1">
          {colors.map((c) => (
            <button
              key={c}
              onClick={() => { setPenColor(c); setIsEraser(false); }}
              className={`w-4 h-4 rounded-full border transition ${
                penColor === c && !isEraser ? 'scale-125 border-white shadow-sm' : 'border-transparent'
              }`}
              style={{ backgroundColor: c }}
            />
          ))}
        </div>

        {/* Thickness */}
        <select
          value={penSize}
          onChange={(e) => setPenSize(Number(e.target.value))}
          className="bg-black/30 border border-border-subtle rounded px-1 text-[11px] text-ink-primary outline-none"
        >
          <option value="2">نازک (2px)</option>
          <option value="4">متوسط (4px)</option>
          <option value="8">ضخیم (8px)</option>
        </select>

        {/* Clear & Visibility */}
        <button
          onClick={handleClear}
          className="p-1.5 rounded hover:bg-white/10 text-ink-muted hover:text-red-400 transition"
          title="پاک کردن کل بوم"
        >
          <RotateCcw className="w-4 h-4" />
        </button>

        <button
          onClick={() => setIsVisible(!isVisible)}
          className="p-1.5 rounded hover:bg-white/10 text-ink-muted hover:text-ink-primary transition"
          title="تغییر نمایش لایه نقاشی"
        >
          {isVisible ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
        </button>
      </div>

      {/* HTML5 Vector Canvas */}
      <canvas
        ref={canvasRef}
        onMouseDown={startDrawing}
        onMouseMove={draw}
        onMouseUp={stopDrawing}
        onMouseLeave={stopDrawing}
        onTouchStart={startDrawing}
        onTouchMove={draw}
        onTouchEnd={stopDrawing}
        className={`w-full h-full cursor-crosshair touch-none ${isVisible ? 'opacity-100' : 'opacity-0 pointer-events-none'}`}
      />
    </div>
  );
};
